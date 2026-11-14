-- Firefight Campaign: tables and functions for walkerwagoner.com/gaming/campaign
-- Run once in the Supabase dashboard: SQL Editor -> New query -> paste -> Run.
-- Safe to run again; it only creates what's missing and replaces the functions.
--
-- How access works:
--   * Anyone can READ campaigns and their data (so a shared link just works).
--   * Nobody can write the tables directly. Every change goes through the
--     gaming_* functions below, which check the campaign's password first.
--   * Passwords are stored only as bcrypt hashes, in a table nobody can read.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.gaming_campaigns (
  slug        text primary key check (slug ~ '^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$'),
  name        text not null check (char_length(name) between 1 and 80),
  game        text not null default 'firefight',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table if not exists public.gaming_secrets (
  slug       text primary key references public.gaming_campaigns(slug) on delete cascade,
  pass_hash  text not null
);

create table if not exists public.gaming_docs (
  campaign    text not null references public.gaming_campaigns(slug) on delete cascade,
  path        text not null check (path ~ '^(camp|live|armies|matches)/[A-Za-z0-9_-]{1,40}$'),
  data        jsonb not null,
  updated_at  timestamptz not null default now(),
  primary key (campaign, path)
);

alter table public.gaming_campaigns enable row level security;
alter table public.gaming_secrets   enable row level security;
alter table public.gaming_docs      enable row level security;

drop policy if exists "anyone can read campaigns" on public.gaming_campaigns;
create policy "anyone can read campaigns" on public.gaming_campaigns for select using (true);
drop policy if exists "anyone can read campaign data" on public.gaming_docs;
create policy "anyone can read campaign data" on public.gaming_docs for select using (true);
-- gaming_secrets has no policies at all, so nobody can read or write it directly.

revoke insert, update, delete on public.gaming_campaigns from anon, authenticated;
revoke insert, update, delete on public.gaming_docs      from anon, authenticated;
revoke all                    on public.gaming_secrets   from anon, authenticated;
grant select on public.gaming_campaigns, public.gaming_docs to anon, authenticated;

-- password check used by every write
create or replace function public.gaming_check(p_slug text, p_pass text)
returns boolean language sql stable security definer set search_path = public, extensions as $$
  select exists (select 1 from public.gaming_secrets s
                 where s.slug = p_slug and s.pass_hash = extensions.crypt(p_pass, s.pass_hash));
$$;

create or replace function public.gaming_create(p_slug text, p_name text, p_pass text)
returns void language plpgsql security definer set search_path = public, extensions as $$
begin
  if p_pass is null or char_length(p_pass) < 4 then raise exception 'Password must be at least 4 characters'; end if;
  if (select count(*) from public.gaming_campaigns where created_at > now() - interval '1 hour') >= 20 then
    raise exception 'Too many campaigns created recently. Try again later.';
  end if;
  insert into public.gaming_campaigns(slug, name) values (p_slug, p_name);
  insert into public.gaming_secrets(slug, pass_hash) values (p_slug, extensions.crypt(p_pass, extensions.gen_salt('bf', 10)));
end $$;

create or replace function public.gaming_put(p_slug text, p_pass text, p_path text, p_data jsonb)
returns void language plpgsql security definer set search_path = public, extensions as $$
begin
  if not public.gaming_check(p_slug, p_pass) then raise exception 'Wrong password' using errcode = '28P01'; end if;
  if p_data is null then
    delete from public.gaming_docs where campaign = p_slug and path = p_path;
  else
    if pg_column_size(p_data) > 400000 then raise exception 'That record is too large'; end if;
    insert into public.gaming_docs(campaign, path, data, updated_at) values (p_slug, p_path, p_data, now())
      on conflict (campaign, path) do update set data = excluded.data, updated_at = now();
  end if;
  update public.gaming_campaigns
     set updated_at = now(),
         name = case when p_path = 'camp/main' and p_data ? 'name' and char_length(p_data->>'name') between 1 and 80
                     then p_data->>'name' else name end
   where slug = p_slug;
end $$;

create or replace function public.gaming_change_pass(p_slug text, p_old text, p_new text)
returns void language plpgsql security definer set search_path = public, extensions as $$
begin
  if not public.gaming_check(p_slug, p_old) then raise exception 'Wrong password' using errcode = '28P01'; end if;
  if p_new is null or char_length(p_new) < 4 then raise exception 'Password must be at least 4 characters'; end if;
  update public.gaming_secrets set pass_hash = extensions.crypt(p_new, extensions.gen_salt('bf', 10)) where slug = p_slug;
end $$;

create or replace function public.gaming_delete(p_slug text, p_pass text)
returns void language plpgsql security definer set search_path = public, extensions as $$
begin
  if not public.gaming_check(p_slug, p_pass) then raise exception 'Wrong password' using errcode = '28P01'; end if;
  delete from public.gaming_campaigns where slug = p_slug;
end $$;

revoke all on function public.gaming_check(text, text)                   from public;
revoke all on function public.gaming_create(text, text, text)            from public;
revoke all on function public.gaming_put(text, text, text, jsonb)        from public;
revoke all on function public.gaming_change_pass(text, text, text)       from public;
revoke all on function public.gaming_delete(text, text)                  from public;
grant execute on function public.gaming_check(text, text)                to anon, authenticated;
grant execute on function public.gaming_create(text, text, text)         to anon, authenticated;
grant execute on function public.gaming_put(text, text, text, jsonb)     to anon, authenticated;
grant execute on function public.gaming_change_pass(text, text, text)    to anon, authenticated;
grant execute on function public.gaming_delete(text, text)               to anon, authenticated;

-- live updates: pages watch gaming_docs for changes
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'gaming_docs') then
    alter publication supabase_realtime add table public.gaming_docs;
  end if;
end $$;
