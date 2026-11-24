-- Entitlement và đếm quota. Quy tắc đếm: docs/architecture/data-model.md §4. Giá trị: plan_entitlements.

-- Gói hiệu lực. Còn quyền: trial, active, cancelled (đã tắt gia hạn, còn hạn), grace.
-- Mất quyền: billing_retry (hết grace), paused, expired, refunded.
create function app.effective_plan(p_uid uuid) returns text
language sql stable set search_path = '' as $$
  select coalesce((
    select s.plan_id from public.subscriptions s
    where s.user_id = p_uid
      and (s.status = 'grace'
           or (s.status in ('trial','active','cancelled')
               and (s.current_period_end is null or s.current_period_end > now())))
  ), 'free')
$$;

-- Giới hạn của 1 key. Thiếu key ở gói hiện tại thì lấy của 'free', thiếu nữa thì 0 (đóng mặc định).
create function app.limit_for(p_uid uuid, p_key text) returns int
language sql stable set search_path = '' as $$
  select coalesce(
    (select e.value from public.plan_entitlements e where e.plan_id = app.effective_plan(p_uid) and e.key = p_key),
    (select e.value from public.plan_entitlements e where e.plan_id = 'free' and e.key = p_key),
    0)
$$;

create function app.user_today(p_uid uuid) returns date
language sql stable set search_path = '' as $$
  select (now() at time zone p.home_tz)::date from public.profiles p where p.id = p_uid
$$;

-- Số lần 1 RRULE kêu trong ngày p_day (xấp xỉ phía server để chống lách; con số chính xác do engine trên máy tính).
-- Hỗ trợ: FREQ DAILY/WEEKLY/MONTHLY/YEARLY, INTERVAL, BYDAY (bỏ qua số thứ tự như 1MO, coi như mọi thứ đó: đếm dư),
-- BYMONTHDAY, BYMONTH, BYHOUR x BYMINUTE (nhiều lần/ngày). HOURLY/MINUTELY: coi như 24 lần/ngày.
create function app.rrule_fires_on(p_rrule text, p_dtstart date, p_day date) returns int
language plpgsql immutable set search_path = '' as $$
declare
  parts jsonb := '{}';
  kv text[];
  part text;
  freq text; ival int; byday text[]; bymonthday int[]; bymonth int[]; nhour int; nmin int;
  wd text := (array['SU','MO','TU','WE','TH','FR','SA'])[extract(dow from p_day)::int + 1];
  ok boolean;
begin
  if p_rrule is null or p_day < p_dtstart then return 0; end if;
  foreach part in array string_to_array(upper(regexp_replace(p_rrule, '^RRULE:', '', 'i')), ';') loop
    kv := string_to_array(part, '=');
    if array_length(kv, 1) = 2 then parts := parts || jsonb_build_object(kv[1], kv[2]); end if;
  end loop;
  freq := parts->>'FREQ';
  ival := greatest(coalesce((parts->>'INTERVAL')::int, 1), 1);
  if parts ? 'BYDAY' then
    select array_agg(regexp_replace(x, '^[+-]?[0-9]+', '')) into byday from unnest(string_to_array(parts->>'BYDAY', ',')) x;
  end if;
  if parts ? 'BYMONTHDAY' then bymonthday := string_to_array(parts->>'BYMONTHDAY', ',')::int[]; end if;
  if parts ? 'BYMONTH' then bymonth := string_to_array(parts->>'BYMONTH', ',')::int[]; end if;
  nhour := coalesce(array_length(string_to_array(parts->>'BYHOUR', ','), 1), 1);
  nmin := coalesce(array_length(string_to_array(parts->>'BYMINUTE', ','), 1), 1);

  if freq in ('HOURLY','MINUTELY','SECONDLY') then return 24; end if;

  ok := case freq
    when 'DAILY' then (p_day - p_dtstart) % ival = 0
    when 'WEEKLY' then
      ((date_trunc('week', p_day)::date - date_trunc('week', p_dtstart)::date) / 7) % ival = 0
      and wd = any(coalesce(byday, array[(array['SU','MO','TU','WE','TH','FR','SA'])[extract(dow from p_dtstart)::int + 1]]))
    when 'MONTHLY' then
      (((extract(year from p_day) * 12 + extract(month from p_day)) -
        (extract(year from p_dtstart) * 12 + extract(month from p_dtstart)))::int % ival = 0)
      and case
        when bymonthday is not null then extract(day from p_day)::int = any(bymonthday)
             or (-1 = any(bymonthday) and p_day = (date_trunc('month', p_day) + interval '1 month - 1 day')::date)
        when byday is not null then wd = any(byday)
        else extract(day from p_day) = extract(day from p_dtstart) end
    when 'YEARLY' then
      ((extract(year from p_day) - extract(year from p_dtstart))::int % ival = 0)
      and extract(month from p_day)::int = any(coalesce(bymonth, array[extract(month from p_dtstart)::int]))
      and case
        when bymonthday is not null then extract(day from p_day)::int = any(bymonthday)
        when byday is not null then wd = any(byday)
        else extract(day from p_day) = extract(day from p_dtstart) end
    else false end;
  if not ok then return 0; end if;
  if freq = 'DAILY' and byday is not null and not (wd = any(byday)) then return 0; end if;
  return nhour * nmin;
end $$;

-- Ngày có nhiều lần nhắc nhất trong 7 ngày tới theo home_tz.
-- Tính: nhắc absolute; nhắc offset của item không lặp; nhắc offset của item lặp kiểu rrule.
-- Không tính phía server: hệ lịch (âm lịch, Hijri) và after_completion (tối đa ~1 lần/kỳ, client chặn chính xác).
create function app.reminders_peak_day(p_uid uuid) returns int
language sql stable set search_path = '' as $$
  with p as (
    select home_tz as tz, (now() at time zone home_tz)::date as today from public.profiles where id = p_uid
  ),
  days as (select (p.today + g)::date as d from p, generate_series(0, 6) g),
  r as (
    select r.trigger_kind, r.at, r.offset_minutes, i.starts_at, i.all_day, i.start_date,
           rc.kind as rkind, rc.rrule, rc.dtstart, rc.until
    from public.reminders r
    join public.items i on i.id = r.item_id
    left join public.recurrences rc on rc.item_id = i.id and rc.deleted_at is null
    where r.user_id = p_uid and r.deleted_at is null and i.deleted_at is null
      and i.status in ('open', 'pending_quota') and r.trigger_kind in ('absolute', 'offset')
  ),
  fires as (
    select case
             when r.trigger_kind = 'absolute' then (r.at at time zone p.tz)::date
             when r.starts_at is not null then ((r.starts_at + make_interval(mins => r.offset_minutes)) at time zone p.tz)::date
             else r.start_date
           end as d, 1 as n
    from r, p
    where r.rkind is null or r.trigger_kind = 'absolute'
    union all
    select days.d, app.rrule_fires_on(r.rrule, (r.dtstart at time zone p.tz)::date, days.d)
    from r, p, days
    where r.rkind = 'rrule' and r.trigger_kind = 'offset'
      and (r.until is null or (r.until at time zone p.tz)::date >= days.d)
  )
  select coalesce(max(total), 0)::int
  from (select f.d, sum(f.n) as total from fires f join days on days.d = f.d group by f.d) x
$$;

-- Mức dùng hiện tại của 1 key.
create function app.usage_for(p_uid uuid, p_key text) returns int
language plpgsql stable set search_path = '' as $$
declare
  v_today date := app.user_today(p_uid);
  v_tz text := (select home_tz from public.profiles where id = p_uid);
  n int;
begin
  case p_key
  when 'max_lists' then
    select count(*) into n from public.lists
    where user_id = p_uid and deleted_at is null and not is_inbox;
  when 'max_active_trips' then
    select count(*) into n from public.trips
    where user_id = p_uid and deleted_at is null and (ends_on is null or ends_on >= v_today);
  when 'max_active_appointments' then
    select count(*) into n from public.items
    where user_id = p_uid and deleted_at is null
      and kind in ('event', 'appointment', 'booking') and status in ('open', 'pending_quota')
      and coalesce((coalesce(ends_at, starts_at) at time zone v_tz)::date, end_date, start_date, v_today) >= v_today;
  when 'max_recurring_series' then
    select count(*) into n from public.recurrences rc join public.items i on i.id = rc.item_id
    where rc.user_id = p_uid and rc.deleted_at is null and i.deleted_at is null
      and i.status not in ('done', 'archived', 'cancelled');
  when 'max_reminders_per_day' then
    n := app.reminders_peak_day(p_uid);
  when 'smart_imports_per_month' then
    -- Đếm cả bản ghi đã xóa (xóa không hoàn lượt); 'failed' (không đọc ra trường nào) không tính.
    select count(*) into n from public.imports
    where user_id = p_uid and kind in ('image', 'pdf', 'xlsx', 'email') and status <> 'failed'
      and date_trunc('month', created_at at time zone v_tz) = date_trunc('month', now() at time zone v_tz);
  else
    n := 0;
  end case;
  return n;
end $$;

revoke all on all functions in schema app from public;
