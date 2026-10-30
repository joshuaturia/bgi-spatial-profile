-- Consultant spatial profile: database schema and access rules.
-- Run once in the Supabase SQL editor. Safe to keep in a public repo:
-- it contains structure and rules only, no project data.

-- 1. Who may read the data -------------------------------------------------
create table if not exists public.allowed_users (
  email text primary key,
  note  text,
  added_at timestamptz default now()
);

-- True when the signed-in user's email is on the allow-list.
-- Kept in a non-exposed schema so it can't be called through the public API.
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;
create or replace function private.is_allowed()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.allowed_users
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;
revoke all on function private.is_allowed() from public, anon;
grant execute on function private.is_allowed() to authenticated;

-- 2. Data tables -----------------------------------------------------------
create table if not exists public.consultants (
  code        text primary key,          -- short key used by elements, e.g. 'F'
  short_name  text not null,
  full_name   text,
  start_month int  not null,             -- months after January of base_year (0 = Jan)
  months      int  not null,             -- contract length
  color_var   text not null,             -- CSS colour token, e.g. '--cF'
  sort        int  default 0
);

create table if not exists public.gis_deliverables (
  code      text primary key,            -- 'D1' ... 'D6'
  due_month numeric not null             -- months after GIS contract start
);

create table if not exists public.themes (
  name     text primary key,
  gis_role text,
  sort     int default 0
);

create table if not exists public.spatial_elements (
  id              bigint generated always as identity primary key,
  consultant_code text not null references public.consultants(code),
  deliverable     text not null,          -- the consultant's own deliverable, e.g. 'D3'
  due_month       numeric not null,       -- months after the consultant's start
  element         text not null,
  data_form       text,
  theme           text references public.themes(name),
  direction       text not null check (direction in ('in','spec','out')),
  feeds           text[] not null default '{}',
  sensitivity     text,
  geography       text,
  note            text
);

-- Free-form settings: page text ('meta'), GIS lane ('gis'), implications cards ('plan').
create table if not exists public.dashboard_settings (
  key   text primary key,
  value jsonb not null
);

-- 3. Row-level security ----------------------------------------------------
-- Every table is locked by default. Signed-in users on the allow-list may read.
-- Nobody can write through the public API; edit data in the Supabase dashboard.
do $$
declare t text;
begin
  foreach t in array array['consultants','gis_deliverables','themes','spatial_elements','dashboard_settings','allowed_users']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('alter table public.%I force row level security', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('revoke insert, update, delete, truncate on public.%I from authenticated', t);
    execute format('grant select on public.%I to authenticated', t);
    execute format('drop policy if exists "allow-listed users read" on public.%I', t);
  end loop;
end $$;

create policy "allow-listed users read" on public.consultants        for select to authenticated using (private.is_allowed());
create policy "allow-listed users read" on public.gis_deliverables   for select to authenticated using (private.is_allowed());
create policy "allow-listed users read" on public.themes             for select to authenticated using (private.is_allowed());
create policy "allow-listed users read" on public.spatial_elements   for select to authenticated using (private.is_allowed());
create policy "allow-listed users read" on public.dashboard_settings for select to authenticated using (private.is_allowed());
-- Users may only see their own allow-list row (used to show "no access" messages).
create policy "allow-listed users read" on public.allowed_users      for select to authenticated
  using (lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')));
