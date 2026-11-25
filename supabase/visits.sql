-- Gorge Bowl: anonymous visit counts (no names, no IP addresses).
-- Each phone gets a random ID stored only on that phone. The app records "this ID looked today"
-- and how many times. Only you can see the numbers (in the SQL Editor); the public can't read them.
-- Run once in Supabase: SQL Editor > New query > paste > Run. Safe to run again.
--
-- To see your numbers, run:
--   select * from daily_stats order by day desc limit 14;

create table if not exists public.devices (
  device    text primary key check (char_length(device) between 8 and 64),
  first_day date not null default (now() at time zone 'America/Los_Angeles')::date
);
create table if not exists public.visits (
  day    date not null default (now() at time zone 'America/Los_Angeles')::date,
  device text not null references public.devices(device) on delete cascade,
  views  integer not null default 1,
  primary key (day, device)
);
alter table public.devices enable row level security;   -- no policies: the public can't read these
alter table public.visits  enable row level security;
revoke all on public.devices, public.visits from anon, authenticated;

-- The app calls this once each time it's opened.
create or replace function public.log_visit(p_device text)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_device is null or char_length(p_device) not between 8 and 64 then return; end if;
  insert into devices (device) values (p_device) on conflict do nothing;
  insert into visits (device) values (p_device)
  on conflict (day, device) do update set views = visits.views + 1;
end $$;
revoke execute on function public.log_visit(text) from public;
grant execute on function public.log_visit(text) to anon, authenticated;

-- Your numbers, one row per day.
create or replace view public.daily_stats with (security_invoker = true) as
  select v.day,
         count(*)                                    as visitors,
         count(*) filter (where d.first_day = v.day) as new_visitors,
         sum(v.views)                                as views,
         (select count(*) from soups s where s.day = v.day) as soups_posted
  from visits v join devices d on d.device = v.device
  group by v.day;
revoke all on public.daily_stats from anon, authenticated;
