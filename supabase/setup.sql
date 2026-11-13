-- Gorge Bowl database setup for Supabase.
-- Paste this whole file into Supabase: SQL Editor > New query > Run.
-- Safe to run again; it won't delete anything.
--
-- How it's protected: anyone can READ restaurants and today's soups,
-- but nobody can write to the tables directly. All writes go through
-- the three functions at the bottom, which enforce the app's rules
-- (length limits, no duplicate restaurants, a customer can't
-- overwrite the restaurant's own post, checks only go up or down by 1).

-- ---------- tables ----------
create table if not exists public.restaurants (
  id         uuid primary key default gen_random_uuid(),
  name       text not null check (char_length(btrim(name)) between 1 and 60),
  town       text not null default '' check (char_length(town) <= 40),
  address    text not null default '' check (char_length(address) <= 120),
  lat        double precision,
  lon        double precision,
  created_at timestamptz not null default now()
);
create unique index if not exists restaurants_name_town_key
  on public.restaurants (lower(btrim(name)), lower(town));

create table if not exists public.soups (
  id            uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  day           date not null default (now() at time zone 'America/Los_Angeles')::date,
  soup          text not null check (char_length(btrim(soup)) between 1 and 40),
  special       text check (special is null or char_length(special) <= 60),
  posted_by     text not null check (posted_by in ('restaurant','customer')),
  checks        integer not null default 0 check (checks >= 0),
  created_at    timestamptz not null default now()
);
create index if not exists soups_day_restaurant_idx
  on public.soups (day, restaurant_id, created_at desc);

-- Today's soup for each restaurant (Pacific time), newest post wins.
create or replace view public.todays_soups with (security_invoker = true) as
  select distinct on (restaurant_id)
         id, restaurant_id, soup, special, posted_by, checks, created_at
  from public.soups
  where day = (now() at time zone 'America/Los_Angeles')::date
  order by restaurant_id, created_at desc;

-- ---------- access: read-only for the public ----------
alter table public.restaurants enable row level security;
alter table public.soups       enable row level security;

drop policy if exists "anyone can read restaurants" on public.restaurants;
create policy "anyone can read restaurants" on public.restaurants
  for select to anon, authenticated using (true);

drop policy if exists "anyone can read soups" on public.soups;
create policy "anyone can read soups" on public.soups
  for select to anon, authenticated using (true);

revoke insert, update, delete on public.restaurants, public.soups from anon, authenticated;
grant select on public.restaurants, public.soups, public.todays_soups to anon, authenticated;

-- ---------- write functions ----------

-- Add a restaurant, or return the existing one with the same name and town.
create or replace function public.add_restaurant(
  p_name text, p_town text default '', p_address text default '',
  p_lat double precision default null, p_lon double precision default null)
returns public.restaurants
language plpgsql security definer set search_path = public as $$
declare r public.restaurants;
begin
  p_name := btrim(coalesce(p_name, ''));
  p_town := btrim(coalesce(p_town, ''));
  if p_name = '' then raise exception 'Restaurant name is required'; end if;
  select * into r from restaurants
   where lower(btrim(name)) = lower(p_name) and lower(town) = lower(p_town);
  if found then return r; end if;
  insert into restaurants (name, town, address, lat, lon)
  values (left(p_name, 60), left(p_town, 40), left(btrim(coalesce(p_address, '')), 120), p_lat, p_lon)
  returning * into r;
  return r;
end $$;

-- Post today's soup. A customer can't replace a post the restaurant made today.
create or replace function public.post_soup(
  p_restaurant_id uuid, p_soup text, p_special text default null, p_posted_by text default 'customer')
returns public.todays_soups
language plpgsql security definer set search_path = public as $$
declare cur public.todays_soups; res public.todays_soups;
begin
  p_soup := btrim(coalesce(p_soup, ''));
  p_special := nullif(btrim(coalesce(p_special, '')), '');
  if p_soup = '' then raise exception 'Soup name is required'; end if;
  if p_posted_by not in ('restaurant', 'customer') then raise exception 'Invalid poster'; end if;
  select * into cur from todays_soups where restaurant_id = p_restaurant_id;
  if found and cur.posted_by = 'restaurant' and p_posted_by = 'customer' then
    raise exception 'The restaurant already posted today''s soup';
  end if;
  insert into soups (restaurant_id, soup, special, posted_by)
  values (p_restaurant_id, left(p_soup, 40), left(p_special, 60), p_posted_by);
  select * into res from todays_soups where restaurant_id = p_restaurant_id;
  return res;
end $$;

-- Add (+1) or remove (-1) a "That's right" check on a soup.
create or replace function public.check_soup(p_soup_id uuid, p_delta integer)
returns integer
language plpgsql security definer set search_path = public as $$
declare n integer;
begin
  if p_delta not in (-1, 1) then raise exception 'Delta must be 1 or -1'; end if;
  update soups set checks = greatest(0, checks + p_delta)
   where id = p_soup_id and day = (now() at time zone 'America/Los_Angeles')::date
  returning checks into n;
  return n;
end $$;

revoke execute on function public.add_restaurant(text, text, text, double precision, double precision) from public;
revoke execute on function public.post_soup(uuid, text, text, text) from public;
revoke execute on function public.check_soup(uuid, integer) from public;
grant execute on function public.add_restaurant(text, text, text, double precision, double precision) to anon, authenticated;
grant execute on function public.post_soup(uuid, text, text, text) to anon, authenticated;
grant execute on function public.check_soup(uuid, integer) to anon, authenticated;
