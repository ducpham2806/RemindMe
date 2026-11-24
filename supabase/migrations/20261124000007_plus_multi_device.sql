-- Plus đăng nhập đồng thời trên nhiều loại thiết bị (ADR-013, sửa đổi 1).
-- Hai giới hạn, đều nằm trong plan_entitlements:
--   max_active_devices     tổng số phiên hoạt động         Free 1, Plus 3
--   max_devices_per_class  số phiên mỗi loại thiết bị      Free 1, Plus 1  (1 điện thoại + 1 tablet + 1 máy tính)
-- Vượt giới hạn thì giữ phiên mới + phiên hoạt động gần nhất, kết thúc phần còn lại.

update public.plan_entitlements set value = 3 where plan_id = 'plus' and key = 'max_active_devices';
insert into public.plan_entitlements (plan_id, key, value) values
  ('free', 'max_devices_per_class', 1),
  ('plus', 'max_devices_per_class', 1);

alter table public.user_sessions
  add column device_class text not null default 'phone' check (device_class in ('phone', 'tablet', 'computer'));
alter table public.user_sessions drop constraint user_sessions_platform_check;
alter table public.user_sessions add constraint user_sessions_platform_check
  check (platform in ('ios', 'ipados', 'android', 'web', 'macos', 'windows', 'linux'));
alter table public.user_sessions drop constraint user_sessions_end_reason_check;
alter table public.user_sessions add constraint user_sessions_end_reason_check
  check (end_reason in ('replaced', 'same_device_relogin', 'signed_out', 'revoked_by_user', 'plan_limit'));
drop index public.user_sessions_notify_idx;
create index user_sessions_notify_idx on public.user_sessions (ended_at)
  where end_reason in ('replaced', 'plan_limit') and revoke_notified_at is null;

-- Loại thiết bị: web/desktop luôn là 'computer'; ios/android do app báo (phone|tablet).
create function app.device_class_of(p_platform text, p_class text) returns text
language sql immutable set search_path = '' as $$
  select case
    when p_platform in ('web', 'macos', 'windows', 'linux') then 'computer'
    when p_platform = 'ipados' then 'tablet'
    when p_class in ('phone', 'tablet', 'computer') then p_class
    else 'phone' end
$$;

-- Chọn phiên phải kết thúc. p_first (phiên mới) luôn được giữ; các phiên khác xét theo last_seen_at mới nhất trước.
-- p_first chưa có trong bảng (xem trước ở session_status) thì truyền p_first_class.
create function app.pick_evictions(p_uid uuid, p_first uuid, p_first_class text, p_skip_device text default null)
returns uuid[]
language plpgsql stable set search_path = '' as $$
declare
  lim_total int := app.limit_for(p_uid, 'max_active_devices');
  lim_class int := app.limit_for(p_uid, 'max_devices_per_class');
  total int := 0;
  per jsonb := '{}';
  r record;
  v_out uuid[] := '{}';
begin
  if p_first is not null then
    total := 1;
    per := jsonb_build_object(p_first_class, 1);
  end if;
  for r in
    select s.id, s.device_class as c from public.user_sessions s
    where s.user_id = p_uid and s.status = 'active' and s.id is distinct from p_first
      and s.device_id is distinct from p_skip_device
    order by s.last_seen_at desc, s.created_at desc
  loop
    if (lim_total <> -1 and total >= lim_total)
       or (lim_class <> -1 and coalesce((per->>r.c)::int, 0) >= lim_class) then
      v_out := v_out || r.id;
    else
      total := total + 1;
      per := per || jsonb_build_object(r.c, coalesce((per->>r.c)::int, 0) + 1);
    end if;
  end loop;
  return v_out;
end $$;

create or replace function app.end_sessions(p_ids uuid[], p_reason text, p_replaced_by uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  update public.user_sessions
    set status = 'ended', ended_at = now(), end_reason = p_reason, replaced_by = p_replaced_by,
        revoke_notified_at = case when p_reason in ('replaced', 'plan_limit') then null else now() end
    where id = any(p_ids) and status = 'active';
  begin
    delete from auth.sessions where id = any(p_ids);
  exception when others then
    null;
  end;
end $$;

-- Gói thay đổi (webhook RevenueCat ghi subscriptions): hạ gói thì cắt bớt thiết bị, giữ máy hoạt động gần nhất.
create function app.enforce_device_limit() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_first uuid;
  v_class text;
  v_evict uuid[];
begin
  select s.id, s.device_class into v_first, v_class from public.user_sessions s
    where s.user_id = new.user_id and s.status = 'active'
    order by s.last_seen_at desc, s.created_at desc limit 1;
  if v_first is null then
    return new;
  end if;
  v_evict := app.pick_evictions(new.user_id, v_first, v_class);
  if cardinality(v_evict) > 0 then
    perform app.end_sessions(v_evict, 'plan_limit', null);
  end if;
  return new;
end $$;

create trigger enforce_device_limit after insert or update on public.subscriptions
  for each row execute function app.enforce_device_limit();

-- session_status: thêm tham số để màn xác nhận biết chính xác máy nào sẽ bị đăng xuất.
drop function public.session_status();
create function public.session_status(device_id text default null, platform text default null, device_class text default null)
returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_sid uuid := app.jwt_session_id();
  s public.user_sessions;
  v_by jsonb;
  v_will jsonb;
begin
  if v_uid is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;
  select * into s from public.user_sessions where id = v_sid and user_id = v_uid;
  if s.replaced_by is not null then
    select jsonb_build_object('platform', r.platform, 'device_model', r.device_model, 'device_class', r.device_class,
                              'country', r.country, 'signed_in_at', r.created_at)
      into v_by from public.user_sessions r where r.id = s.replaced_by;
  end if;
  if s.id is null then
    select coalesce(jsonb_agg(jsonb_build_object('device_id', o.device_id, 'platform', o.platform, 'device_model', o.device_model,
                                                 'device_class', o.device_class, 'country', o.country, 'last_seen_at', o.last_seen_at)
                              order by o.last_seen_at desc), '[]')
      into v_will from public.user_sessions o
      where o.id = any(app.pick_evictions(v_uid, coalesce(v_sid, gen_random_uuid()), app.device_class_of($2, $3), $1));
  end if;
  return jsonb_build_object(
    'session_id', v_sid,
    'state', case when s.id is null then 'unclaimed' else s.status end,
    'end_reason', s.end_reason,
    'ended_at', s.ended_at,
    'replaced_by', v_by,
    'max_active_devices', app.limit_for(v_uid, 'max_active_devices'),
    'max_devices_per_class', app.limit_for(v_uid, 'max_devices_per_class'),
    -- Chỉ khi phiên này chưa claim: các máy sẽ bị đăng xuất nếu tiếp tục (không gồm phiên cũ trên chính máy này).
    'will_replace', v_will);
end $$;

-- session_claim: giới hạn theo tổng + theo loại thiết bị.
create or replace function public.session_claim(device_id text, device jsonb default '{}') returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_sid uuid := app.jwt_session_id();
  v_device text := $1;
  v_info jsonb := coalesce($2, '{}');
  v_status text;
  v_class text := app.device_class_of(v_info->>'platform', v_info->>'device_class');
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
    insert into public.user_sessions (id, user_id, device_id, platform, device_class, device_model, os_version, app_version,
                                      locale, tz, ip, country)
    values (v_sid, v_uid, v_device, v_info->>'platform', v_class, v_info->>'device_model', v_info->>'os_version',
            v_info->>'app_version', v_info->>'locale', v_info->>'tz', v_ip, v_country);
  else
    update public.user_sessions s set last_seen_at = now(), app_version = coalesce(v_info->>'app_version', s.app_version),
           os_version = coalesce(v_info->>'os_version', s.os_version)
      where s.id = v_sid;
    select s.device_class into v_class from public.user_sessions s where s.id = v_sid;
  end if;

  select array_agg(s.id) into v_same from public.user_sessions s
    where s.user_id = v_uid and s.status = 'active' and s.device_id = v_device and s.id <> v_sid;
  if v_same is not null then
    perform app.end_sessions(v_same, 'same_device_relogin', v_sid);
  end if;

  v_old := app.pick_evictions(v_uid, v_sid, v_class);
  if cardinality(v_old) > 0 then
    select jsonb_agg(jsonb_build_object('session_id', s.id, 'device_id', s.device_id, 'platform', s.platform,
                                        'device_class', s.device_class, 'device_model', s.device_model, 'last_seen_at', s.last_seen_at))
      into v_replaced from public.user_sessions s where s.id = any(v_old);
    perform app.end_sessions(v_old, 'replaced', v_sid);
  end if;

  return jsonb_build_object('session_id', v_sid, 'state', 'active', 'device_class', v_class,
                            'replaced', coalesce(v_replaced, '[]'));
end $$;

revoke all on function public.session_status(text, text, text) from public, anon;
grant execute on function public.session_status(text, text, text) to authenticated;
revoke all on all functions in schema app from public;
grant execute on function app.session_is_active() to authenticated;
