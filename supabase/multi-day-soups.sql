-- Gorge Bowl: multi-day soups.
-- Run AFTER restaurant-links.sql: SQL Editor > New query > paste > Run. Safe to run again.
--
-- A restaurant posting with its private link can say the soup runs for several days
-- (up to 7), so it doesn't have to post every day. Customers always post for today only.

begin;

alter table public.soups add column if not exists until_day date;
update public.soups set until_day = day where until_day is null;
alter table public.soups alter column until_day set not null;
alter table public.soups drop constraint if exists soups_until_after_day;
alter table public.soups add constraint soups_until_after_day check (until_day >= day and until_day <= day + 6);
create index if not exists soups_until_idx on public.soups (until_day);

-- Today's soup per restaurant: any post whose run covers today; the newest post wins.
create or replace view public.todays_soups with (security_invoker = true) as
  select distinct on (restaurant_id)
         id, restaurant_id, soup, special, posted_by, checks, created_at, until_day
  from public.soups
  where (now() at time zone 'America/Los_Angeles')::date between day and until_day
  order by restaurant_id, created_at desc;
grant select on public.todays_soups to anon, authenticated;

drop function if exists public.post_soup(uuid, text, text, text, text);
create or replace function public.post_soup(
  p_restaurant_id uuid, p_soup text, p_special text default null,
  p_key text default null, p_posted_by text default null, p_days integer default 1)
returns public.todays_soups
language plpgsql security definer set search_path = public as $$
declare cur public.todays_soups; res public.todays_soups; v_by text := 'customer';
        v_today date := (now() at time zone 'America/Los_Angeles')::date; v_days integer := 1;
begin
  p_soup := btrim(coalesce(p_soup, ''));
  p_special := nullif(btrim(coalesce(p_special, '')), '');
  if p_soup = '' then raise exception 'Soup name is required'; end if;
  if p_key is not null and exists (
    select 1 from restaurant_keys where restaurant_id = p_restaurant_id and key_hash = key_fingerprint(p_key)
  ) then v_by := 'restaurant'; end if;
  if v_by = 'restaurant' then v_days := greatest(1, least(7, coalesce(p_days, 1))); end if;
  select * into cur from todays_soups where restaurant_id = p_restaurant_id;
  if found and cur.posted_by = 'restaurant' and v_by = 'customer' then
    raise exception 'The restaurant already posted today''s soup';
  end if;
  insert into soups (restaurant_id, day, until_day, soup, special, posted_by)
  values (p_restaurant_id, v_today, v_today + (v_days - 1), left(p_soup, 40), left(p_special, 60), v_by);
  select * into res from todays_soups where restaurant_id = p_restaurant_id;
  return res;
end $$;
revoke execute on function public.post_soup(uuid, text, text, text, text, integer) from public;
grant execute on function public.post_soup(uuid, text, text, text, text, integer) to anon, authenticated;

-- Checks work on any day a soup is running, not only the day it was posted.
create or replace function public.check_soup(p_soup_id uuid, p_delta integer)
returns integer
language plpgsql security definer set search_path = public as $$
declare n integer; v_today date := (now() at time zone 'America/Los_Angeles')::date;
begin
  if p_delta not in (-1, 1) then raise exception 'Delta must be 1 or -1'; end if;
  update soups set checks = greatest(0, checks + p_delta)
   where id = p_soup_id and v_today between day and until_day
  returning checks into n;
  return n;
end $$;

commit;
