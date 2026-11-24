-- Supabase shim: chỉ dùng cho Postgres thuần (CI, máy dev không có Docker).
-- Tái tạo phần tối thiểu mà Supabase có sẵn: schema auth + extensions, các role, auth.uid(), default privileges.
-- KHÔNG chạy file này trên project Supabase thật.

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then create role anon nologin noinherit; end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then create role authenticated nologin noinherit; end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then create role service_role nologin noinherit bypassrls; end if;
end $$;

create schema if not exists auth;
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
grant usage on schema extensions to anon, authenticated, service_role;

create table if not exists auth.users (
  id uuid primary key,
  email text,
  is_anonymous bool not null default false,
  created_at timestamptz not null default now()
);

-- Phiên đăng nhập của GoTrue (rút gọn). JWT của user có claim session_id = auth.sessions.id.
create table if not exists auth.sessions (
  id uuid primary key,
  user_id uuid not null references auth.users on delete cascade,
  created_at timestamptz not null default now()
);

-- Giống định nghĩa của Supabase: đọc claim 'sub' từ JWT mà PostgREST đặt vào GUC.
create or replace function auth.uid() returns uuid
language sql stable as $$
  select coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;

create or replace function auth.role() returns text
language sql stable as $$
  select coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;

grant usage on schema auth to anon, authenticated, service_role;
create or replace function auth.jwt() returns jsonb
language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claim', true), ''), nullif(current_setting('request.jwt.claims', true), ''))::jsonb
$$;

grant execute on function auth.uid(), auth.role(), auth.jwt() to anon, authenticated, service_role;

-- Supabase cấp sẵn mọi quyền trên schema public cho 3 role này; migration phải tự thu hồi.
grant usage on schema public to anon, authenticated, service_role;
alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to anon, authenticated, service_role;
alter default privileges in schema public grant all on functions to anon, authenticated, service_role;
