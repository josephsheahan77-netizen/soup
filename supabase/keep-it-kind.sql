-- Gorge Bowl: keep it kind. Rejects crude words and complaints in soups, specials and restaurant names.
-- Run once in Supabase: SQL Editor > New query > paste > Run. Safe to run again.
-- To add a word later, add it to the list in kind_text() and run this file again.

create or replace function public.kind_text(p text)
returns boolean language sql immutable as $$
  select coalesce(p, '') !~* (
    '\m(' ||
    -- crude words (with common endings)
    'fuck\w*|f+u+c+k+|shit\w*|bullshit|bitch\w*|cunt\w*|asshole\w*|dick|dicks|dickhead|pussy|piss\w*|bastard\w*|' ||
    'whore\w*|slut\w*|fag\w*|nigg\w*|retard\w*|twat\w*|wank\w*|motherf\w*|' ||
    -- complaints (this is an information app, not a review site)
    'sucks|suck|worst|disgusting|gross|nasty|terrible|awful|horrible|crap|crappy|garbage|trash|vomit|puke|food\s*poisoning' ||
    ')\M')
$$;

create or replace function public.check_kind() returns trigger
language plpgsql set search_path = public as $$
begin
  if tg_table_name = 'soups' then
    if not kind_text(new.soup) or not kind_text(new.special) then
      raise exception 'Keep it about soup, please';
    end if;
  elsif tg_table_name = 'restaurants' then
    if not kind_text(new.name) then
      raise exception 'Keep it about soup, please';
    end if;
  end if;
  return new;
end $$;

drop trigger if exists soups_kind on public.soups;
create trigger soups_kind before insert or update of soup, special on public.soups
  for each row execute function public.check_kind();

drop trigger if exists restaurants_kind on public.restaurants;
create trigger restaurants_kind before insert or update of name on public.restaurants
  for each row execute function public.check_kind();
