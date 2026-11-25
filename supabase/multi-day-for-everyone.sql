-- Gorge Bowl: anyone can post a soup for several days (up to 5), so it doesn't reset each night.
-- Run AFTER multi-day-soups.sql: SQL Editor > New query > paste > Run. Safe to run again.
-- A multi-day post by a customer isn't locked: the next person can still fix it.
-- (A restaurant posting with its private link can still go up to 7 days, and its post stays locked.)

create or replace function public.post_soup(
  p_restaurant_id uuid, p_soup text, p_special text default null,
  p_key text default null, p_posted_by text default null, p_days integer default 1)
returns public.todays_soups
language plpgsql security definer set search_path = public as $$
declare cur public.todays_soups; res public.todays_soups; v_by text := 'customer';
        v_today date := (now() at time zone 'America/Los_Angeles')::date; v_days integer;
begin
  p_soup := btrim(coalesce(p_soup, ''));
  p_special := nullif(btrim(coalesce(p_special, '')), '');
  if p_soup = '' then raise exception 'Soup name is required'; end if;
  if p_key is not null and exists (
    select 1 from restaurant_keys where restaurant_id = p_restaurant_id and key_hash = key_fingerprint(p_key)
  ) then v_by := 'restaurant'; end if;
  v_days := greatest(1, least(case when v_by = 'restaurant' then 7 else 5 end, coalesce(p_days, 1)));
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
