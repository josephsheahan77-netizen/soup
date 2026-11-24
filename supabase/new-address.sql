-- Gorge Bowl: restaurant links use the new address, soupsandtunes.com.
-- Run once in Supabase: SQL Editor > New query > paste > Run. Safe to run again.
-- (Links you already sent keep working; they forward to the new address.)

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
