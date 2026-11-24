-- Một tài khoản chỉ hoạt động trên N thiết bị cùng lúc (ADR-013; N = entitlement max_active_devices, mặc định 1).
-- Đăng nhập thiết bị mới → phiên cũ bị kết thúc ngay (JWT cũ dù chưa hết hạn cũng không đọc/ghi được nữa).
-- Bảng user_sessions vừa là phiên đang hoạt động vừa là lịch sử đăng nhập.

insert into public.plan_entitlements (plan_id, key, value) values
  ('free', 'max_active_devices', 1),
  ('plus', 'max_active_devices', 1);

create table public.user_sessions (
  id uuid primary key,                         -- = claim session_id trong JWT Supabase (auth.sessions.id)
  user_id uuid not null references public.profiles on delete cascade,
  device_id text not null,
  platform text check (platform in ('ios', 'android', 'web')),
  device_model text, os_version text, app_version text,
  locale text, tz text check (app.is_valid_tz(tz)),
  ip inet,                                     -- lấy từ header lúc đăng nhập; xóa sau 90 ngày (security-privacy §6)
  country text check (country ~ '^[A-Z]{2}$'), -- từ header CDN (cf-ipcountry), không định vị chính xác
  status text not null default 'active' check (status in ('active', 'ended')),
  created_at timestamptz not null default now(),   -- thời điểm đăng nhập trên thiết bị này
  last_seen_at timestamptz not null default now(),
  ended_at timestamptz,
  end_reason text check (end_reason in ('replaced', 'same_device_relogin', 'signed_out', 'revoked_by_user')),
  replaced_by uuid references public.user_sessions on delete set null,
  revoke_notified_at timestamptz,              -- worker đã push 'session.revoked' tới thiết bị cũ
  check ((status = 'ended') = (ended_at is not null and end_reason is not null))
);
create index user_sessions_user_idx on public.user_sessions (user_id, created_at desc);
create index user_sessions_active_idx on public.user_sessions (user_id, last_seen_at) where status = 'active';
create index user_sessions_notify_idx on public.user_sessions (ended_at)
  where end_reason = 'replaced' and revoke_notified_at is null;

alter table public.user_sessions enable row level security;
revoke all on public.user_sessions from anon, authenticated;
grant select on public.user_sessions to authenticated;

-- ---------------------------------------------------------------- helpers

create function app.jwt_session_id() returns uuid
language sql stable set search_path = '' as $$
  select (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'session_id')::uuid
$$;

-- Phiên của JWT hiện tại còn hiệu lực? Dùng trong RLS (bọc (select ...) để chỉ tính 1 lần mỗi câu lệnh).
create function app.session_is_active() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.user_sessions s
    where s.id = app.jwt_session_id() and s.user_id = auth.uid() and s.status = 'active')
$$;

-- PostgREST đổi SQLSTATE 'PTxyz' thành HTTP xyz: app nhận 403 + message, không lặp refresh token như với 401.
create function app.require_active_session() returns void
language plpgsql stable security definer set search_path = '' as $$
declare
  v_sid uuid := app.jwt_session_id();
  v_status text;
begin
  if auth.uid() is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;
  if v_sid is null then
    raise exception 'session_missing' using errcode = 'PT403';
  end if;
  select s.status into v_status from public.user_sessions s where s.id = v_sid and s.user_id = auth.uid();
  if v_status is null then
    raise exception 'session_not_claimed' using errcode = 'PT403', hint = 'call session_claim after sign-in';
  elsif v_status <> 'active' then
    raise exception 'session_revoked' using errcode = 'PT403', hint = 'call session_status, then sign in again';
  end if;
end $$;

-- Cập nhật last_seen_at, tối đa 1 lần / 5 phút để không ghi mỗi request.
create function app.touch_session() returns void
language sql security definer set search_path = '' as $$
  update public.user_sessions set last_seen_at = now()
  where id = app.jwt_session_id() and status = 'active' and last_seen_at < now() - interval '5 minutes'
$$;

create function app.request_header(p_name text) returns text
language sql stable set search_path = '' as $$
  select nullif(current_setting('request.headers', true), '')::jsonb ->> p_name
$$;

create function app.end_sessions(p_ids uuid[], p_reason text, p_replaced_by uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  update public.user_sessions
    set status = 'ended', ended_at = now(), end_reason = p_reason, replaced_by = p_replaced_by,
        revoke_notified_at = case when p_reason = 'replaced' then null else now() end
    where id = any(p_ids) and status = 'active';
  -- Xóa phiên GoTrue để refresh token cũng chết. Không có quyền (cấu hình Supabase khác) thì bỏ qua:
  -- RLS + require_active_session vẫn chặn JWT cũ.
  begin
    delete from auth.sessions where id = any(p_ids);
  exception when others then
    null;
  end;
end $$;

-- ---------------------------------------------------------------- RLS: chỉ phiên đang hoạt động mới đọc được

do $$
declare t text;
begin
  for t in
    select name from app.sync_tables
    union all select unnest(array['subscriptions', 'usage_counters', 'devices', 'mailbox_messages', 'integrations', 'user_sessions'])
  loop
    execute format('drop policy if exists own_rows_select on public.%I', t);  -- user_sessions: chưa có, bỏ qua
    execute format('create policy own_rows_select on public.%I for select to authenticated
                    using (user_id = (select auth.uid()) and (select app.session_is_active()))', t);
  end loop;
end $$;
drop policy own_profile_select on public.profiles;
drop policy own_profile_update on public.profiles;
create policy own_profile_select on public.profiles for select to authenticated
  using (id = (select auth.uid()) and (select app.session_is_active()));
create policy own_profile_update on public.profiles for update to authenticated
  using (id = (select auth.uid()) and (select app.session_is_active()))
  with check (id = (select auth.uid()));

-- ---------------------------------------------------------------- RPC phiên

-- Trạng thái phiên hiện tại; gọi được cả khi phiên đã bị kết thúc (để app hiện "đã đăng nhập ở thiết bị khác").
create function public.session_status() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_sid uuid := app.jwt_session_id();
  s public.user_sessions;
  v_by jsonb;
begin
  if v_uid is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;
  select * into s from public.user_sessions where id = v_sid and user_id = v_uid;
  if s.replaced_by is not null then
    select jsonb_build_object('platform', r.platform, 'device_model', r.device_model, 'country', r.country, 'signed_in_at', r.created_at)
      into v_by from public.user_sessions r where r.id = s.replaced_by;
  end if;
  return jsonb_build_object(
    'session_id', v_sid,
    'state', case when s.id is null then 'unclaimed' else s.status end,
    'end_reason', s.end_reason,
    'ended_at', s.ended_at,
    'replaced_by', v_by,
    'max_active_devices', app.limit_for(v_uid, 'max_active_devices'),
    -- Thiết bị sẽ bị đăng xuất nếu claim: chỉ trả khi phiên này chưa claim (màn xác nhận trước khi đăng nhập).
    'active_elsewhere', case when s.id is null then (
      select coalesce(jsonb_agg(jsonb_build_object('device_id', o.device_id, 'platform', o.platform, 'device_model', o.device_model,
                                                   'country', o.country, 'last_seen_at', o.last_seen_at) order by o.last_seen_at desc), '[]')
      from public.user_sessions o where o.user_id = v_uid and o.status = 'active') end);
end $$;

-- Gọi ngay sau đăng nhập (sau profile_init). Kết thúc phiên cũ nếu vượt max_active_devices, ghi lịch sử.
-- device: {platform, device_model, os_version, app_version, locale, tz}
create function public.session_claim(device_id text, device jsonb default '{}') returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_sid uuid := app.jwt_session_id();
  v_device text := $1;
  v_info jsonb := coalesce($2, '{}');
  v_status text;
  v_lim int;
  v_same uuid[];
  v_old uuid[];
  v_ip inet;
  v_country text;
  v_replaced jsonb;
begin
  if v_uid is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;
  if v_sid is null or coalesce(v_device, '') = '' then
    raise exception 'invalid: session_id claim and device_id are required' using errcode = '22023';
  end if;
  if not exists (select 1 from public.profiles p where p.id = v_uid) then
    raise exception 'profile_missing: call profile_init first' using errcode = 'P0002';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(v_uid::text, 43));

  select s.status into v_status from public.user_sessions s where s.id = v_sid;
  if v_status = 'ended' then
    -- Phiên đã bị đá không được tự giành lại: phải đăng nhập lại để có session_id mới.
    raise exception 'session_revoked' using errcode = 'PT403';
  end if;

  if v_status is null then
    begin
      v_ip := split_part(coalesce(app.request_header('cf-connecting-ip'), app.request_header('x-forwarded-for')), ',', 1)::inet;
    exception when others then
      v_ip := null;
    end;
    v_country := upper(app.request_header('cf-ipcountry'));
    if v_country !~ '^[A-Z]{2}$' then v_country := null; end if;
    insert into public.user_sessions (id, user_id, device_id, platform, device_model, os_version, app_version, locale, tz, ip, country)
    values (v_sid, v_uid, v_device, v_info->>'platform', v_info->>'device_model', v_info->>'os_version', v_info->>'app_version',
            v_info->>'locale', v_info->>'tz', v_ip, v_country);
  else
    update public.user_sessions s set last_seen_at = now(), app_version = coalesce(v_info->>'app_version', s.app_version),
           os_version = coalesce(v_info->>'os_version', s.os_version)
      where s.id = v_sid;
  end if;

  -- Đăng nhập lại trên chính thiết bị này (cài lại app, đổi tài khoản rồi quay lại): kết thúc phiên cũ, không cần báo.
  select array_agg(s.id) into v_same from public.user_sessions s
    where s.user_id = v_uid and s.status = 'active' and s.device_id = v_device and s.id <> v_sid;
  if v_same is not null then
    perform app.end_sessions(v_same, 'same_device_relogin', v_sid);
  end if;

  -- Vượt số thiết bị cho phép: kết thúc phiên ít hoạt động gần đây nhất.
  v_lim := app.limit_for(v_uid, 'max_active_devices');
  if v_lim <> -1 then
    select array_agg(x.id) into v_old from (
      select s.id from public.user_sessions s
      where s.user_id = v_uid and s.status = 'active' and s.id <> v_sid
      order by s.last_seen_at desc
      offset greatest(v_lim - 1, 0)
    ) x;
    if v_old is not null then
      select jsonb_agg(jsonb_build_object('session_id', s.id, 'device_id', s.device_id, 'platform', s.platform,
                                          'device_model', s.device_model, 'last_seen_at', s.last_seen_at))
        into v_replaced from public.user_sessions s where s.id = any(v_old);
      perform app.end_sessions(v_old, 'replaced', v_sid);
    end if;
  end if;

  return jsonb_build_object('session_id', v_sid, 'state', 'active', 'replaced', coalesce(v_replaced, '[]'));
end $$;

-- Đăng xuất phiên hiện tại (mặc định) hoặc một phiên khác của mình (từ màn "Thiết bị & đăng nhập").
create function public.session_end(session_id uuid default null) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_target uuid := coalesce($1, app.jwt_session_id());
begin
  if v_uid is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;
  if v_target <> app.jwt_session_id() then
    perform app.require_active_session();
  end if;
  if not exists (select 1 from public.user_sessions s where s.id = v_target and s.user_id = v_uid) then
    return jsonb_build_object('ended', false);
  end if;
  perform app.end_sessions(array[v_target],
    case when v_target = app.jwt_session_id() then 'signed_out' else 'revoked_by_user' end, null);
  return jsonb_build_object('ended', true);
end $$;

-- ---------------------------------------------------------------- bọc RPC cũ bằng kiểm tra phiên

alter function public.sync_push(text, jsonb) set schema app;
alter function app.sync_push(text, jsonb) rename to sync_push_core;
alter function public.sync_pull(bigint, int) set schema app;
alter function app.sync_pull(bigint, int) rename to sync_pull_core;
alter function public.quota_status() set schema app;
alter function app.quota_status() rename to quota_status_core;
revoke all on function app.sync_push_core(text, jsonb), app.sync_pull_core(bigint, int), app.quota_status_core()
  from public, anon, authenticated;

create function public.sync_push(device_id text, mutations jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
begin
  perform app.require_active_session();
  perform app.touch_session();
  return app.sync_push_core($1, $2);
end $$;

create function public.sync_pull(since bigint default 0, lim int default 500) returns jsonb
language plpgsql security definer set search_path = '' as $$
begin
  perform app.require_active_session();
  perform app.touch_session();
  return app.sync_pull_core($1, $2);
end $$;

create function public.quota_status() returns jsonb
language plpgsql security definer set search_path = '' as $$
begin
  perform app.require_active_session();
  return app.quota_status_core();
end $$;

-- profile_init chạy trước session_claim, nhưng phiên đã bị đá thì không được dùng nó để đọc profile.
alter function public.profile_init(text, text, text, text) set schema app;
alter function app.profile_init(text, text, text, text) rename to profile_init_core;
revoke all on function app.profile_init_core(text, text, text, text) from public, anon, authenticated;
create function public.profile_init(ui_locale text, region text, home_tz text, display_name text default null) returns jsonb
language plpgsql security definer set search_path = '' as $$
begin
  if exists (select 1 from public.user_sessions s where s.id = app.jwt_session_id() and s.status = 'ended') then
    raise exception 'session_revoked' using errcode = 'PT403';
  end if;
  return app.profile_init_core($1, $2, $3, $4);
end $$;

revoke all on function public.sync_push(text, jsonb), public.sync_pull(bigint, int), public.quota_status(),
  public.profile_init(text, text, text, text), public.session_status(), public.session_claim(text, jsonb),
  public.session_end(uuid) from public, anon;
grant execute on function public.sync_push(text, jsonb), public.sync_pull(bigint, int), public.quota_status(),
  public.profile_init(text, text, text, text), public.session_status(), public.session_claim(text, jsonb),
  public.session_end(uuid) to authenticated;
revoke all on all functions in schema app from public;
grant execute on function app.session_is_active() to authenticated;
