-- Gorge Bowl: private restaurant links.
-- Run this once in Supabase: SQL Editor > New query > paste > Run. Safe to run again.
--
-- Each restaurant can get a private link from Joe. Opening it on the restaurant's phone makes
-- that phone "the restaurant": its posts show as "Posted by the restaurant" and can't be
-- overwritten by customers. Everyone else posts as a customer. No passwords, no accounts.
--
-- To make a restaurant's link (in the SQL Editor):
--   select make_restaurant_link('pFriem');
-- To make a new link (the old one stops working), run the same line again.

begin;

-- Already set up multi-day soups? Then this file has done its job: stop without changing anything.
do $$ begin
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'soups' and column_name = 'until_day') then
    raise exception 'Restaurant links are already set up (multi-day soups is installed too). Nothing to do.';
  end if;
end $$;

-- Only a fingerprint (hash) of each link is stored, never the link itself.
create table if not exists public.restaurant_keys (
  restaurant_id uuid primary key references public.restaurants(id) on delete cascade,
  key_hash      text not null unique,
  created_at    timestamptz not null default now()
);
alter table public.restaurant_keys enable row level security;   -- no policies: the public can't see it
revoke all on public.restaurant_keys from anon, authenticated;

create or replace function public.key_fingerprint(p_key text)
returns text language sql immutable set search_path = public as $$
  select encode(sha256(convert_to(coalesce(p_key, ''), 'UTF8')), 'hex')
$$;

-- Make (or remake) a restaurant's private link. Only runnable from the SQL Editor.
create or replace function public.make_restaurant_link(
  p_name text, p_site text default 'https://soupsandtunes.com/gorge/')
returns text
language plpgsql security definer set search_path = public as $$
declare r public.restaurants; n integer; k text;
begin
  select count(*) into n from restaurants where lower(btrim(name)) = lower(btrim(p_name));
  if n = 0 then raise exception 'No restaurant named "%". Check the spelling in the restaurants table.', p_name; end if;
  if n > 1 then raise exception 'More than one restaurant is named "%". Ask Claude to pick by town.', p_name; end if;
  select * into r from restaurants where lower(btrim(name)) = lower(btrim(p_name));
  k := replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', '');
  insert into restaurant_keys (restaurant_id, key_hash) values (r.id, key_fingerprint(k))
  on conflict (restaurant_id) do update set key_hash = excluded.key_hash, created_at = now();
  return p_site || '#r=' || k;
end $$;
revoke execute on function public.make_restaurant_link(text, text) from public, anon, authenticated;

-- The app asks: which restaurant does this link belong to?
create or replace function public.restaurant_for_key(p_key text)
returns table (id uuid, name text, town text)
language sql stable security definer set search_path = public as $$
  select r.id, r.name, r.town
  from restaurant_keys k join restaurants r on r.id = k.restaurant_id
  where k.key_hash = key_fingerprint(p_key)
$$;
revoke execute on function public.restaurant_for_key(text) from public;
grant execute on function public.restaurant_for_key(text) to anon, authenticated;

-- Posting: the restaurant's link decides who's posting, not a menu choice.
-- (p_posted_by is still accepted from older copies of the app, but ignored.)
drop function if exists public.post_soup(uuid, text, text, text);
create or replace function public.post_soup(
  p_restaurant_id uuid, p_soup text, p_special text default null,
  p_key text default null, p_posted_by text default null)
returns public.todays_soups
language plpgsql security definer set search_path = public as $$
declare cur public.todays_soups; res public.todays_soups; v_by text := 'customer';
begin
  p_soup := btrim(coalesce(p_soup, ''));
  p_special := nullif(btrim(coalesce(p_special, '')), '');
  if p_soup = '' then raise exception 'Soup name is required'; end if;
  if p_key is not null and exists (
    select 1 from restaurant_keys where restaurant_id = p_restaurant_id and key_hash = key_fingerprint(p_key)
  ) then v_by := 'restaurant'; end if;
  select * into cur from todays_soups where restaurant_id = p_restaurant_id;
  if found and cur.posted_by = 'restaurant' and v_by = 'customer' then
    raise exception 'The restaurant already posted today''s soup';
  end if;
  insert into soups (restaurant_id, soup, special, posted_by)
  values (p_restaurant_id, left(p_soup, 40), left(p_special, 60), v_by);
  select * into res from todays_soups where restaurant_id = p_restaurant_id;
  return res;
end $$;
revoke execute on function public.post_soup(uuid, text, text, text, text) from public;
grant execute on function public.post_soup(uuid, text, text, text, text) to anon, authenticated;

commit;
