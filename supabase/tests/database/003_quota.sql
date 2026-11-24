-- Quota trong sync_push (data-model.md §4, pricing-entitlements.md §2-3).
begin;
\ir _helpers.psql
select plan(21);

select pg_temp.mk_user(pg_temp.u('free'), 'Asia/Ho_Chi_Minh', 'VN', 'vi-VN');
select pg_temp.mk_user(pg_temp.u('plus'), 'America/New_York', 'US', 'en-US');
insert into public.subscriptions (user_id, plan_id, status, current_period_end)
  values (pg_temp.u('plus'), 'plus', 'active', now() + interval '30 days');

create temp table r (n int, res jsonb);
grant all on r to authenticated;

create function pg_temp.appt(p_name text, p_starts timestamptz, p_status text default 'open') returns jsonb
language sql as $$ select pg_temp.up('items', pg_temp.u(p_name),
  jsonb_build_object('kind', 'appointment', 'title', p_name, 'starts_at', p_starts, 'status', p_status)) $$;

-- Lịch hẹn đang hoạt động: Free 10.
select pg_temp.push(pg_temp.u('free'), (select jsonb_agg(pg_temp.appt('f' || g, now() + make_interval(days => g))) from generate_series(1, 10) g));
select is(app.usage_for(pg_temp.u('free'), 'max_active_appointments'), 10, '10 lịch hẹn tương lai được tạo');
insert into r select 1, pg_temp.push(pg_temp.u('free'), jsonb_build_array(pg_temp.appt('f11', now() + interval '20 days')));
select is((select res->0->>'status' from r where n = 1), 'quota_exceeded', 'lịch hẹn thứ 11 bị từ chối');
select is((select res->0->'details' from r where n = 1), '{"key":"max_active_appointments","limit":10,"used":10}'::jsonb,
  'chi tiết quota cho paywall');
select ok(not exists (select 1 from public.items where id = pg_temp.u('f11')), 'mutation bị từ chối không để lại dữ liệu');

-- Lịch hẹn đã qua không tính.
insert into r select 2, pg_temp.push(pg_temp.u('free'), jsonb_build_array(pg_temp.appt('past', now() - interval '3 days')));
select is((select res->0->>'status' from r where n = 2), 'ok', 'lịch hẹn đã qua không tính quota');

-- Tạo offline ở pending_quota: vượt thì thành archived/quota (không mất dữ liệu).
insert into r select 3, pg_temp.push(pg_temp.u('free'), jsonb_build_array(pg_temp.appt('offline', now() + interval '5 days', 'pending_quota')));
select is((select res->0->>'status' from r where n = 3), 'quota_exceeded', 'pending_quota vượt hạn mức: quota_exceeded');
select is((select status || '/' || archived_reason from public.items where id = pg_temp.u('offline')), 'archived/quota',
  'pending_quota vượt hạn mức được lưu ở archived/quota');

-- Sửa item cũ khi đang ở giới hạn: vẫn được (không làm tăng mức dùng).
insert into r select 4, pg_temp.push(pg_temp.u('free'), jsonb_build_array(
  pg_temp.up('items', pg_temp.u('f1'), '{"title":"renamed"}', 1764000000001)));
select is((select res->0->>'status' from r where n = 4), 'ok', 'sửa item khi đang ở giới hạn vẫn được');

-- pending_quota còn chỗ thì được mở.
select pg_temp.push(pg_temp.u('free'), jsonb_build_array(pg_temp.del('items', pg_temp.u('f10'))));
insert into r select 5, pg_temp.push(pg_temp.u('free'), jsonb_build_array(pg_temp.appt('offline2', now() + interval '5 days', 'pending_quota')));
select is((select res->0->'server_row'->>'status' from r where n = 5), 'open', 'pending_quota trong hạn mức thành open');

-- Plus không giới hạn; hạ gói giữ dữ liệu, chỉ chặn tạo thêm.
select pg_temp.push(pg_temp.u('plus'), (select jsonb_agg(pg_temp.appt('p' || g, now() + make_interval(days => g))) from generate_series(1, 12) g));
select is(app.usage_for(pg_temp.u('plus'), 'max_active_appointments'), 12, 'Plus tạo được 12 lịch hẹn');
update public.subscriptions set status = 'expired' where user_id = pg_temp.u('plus');
select is(app.effective_plan(pg_temp.u('plus')), 'free', 'hết hạn thì về free');
insert into r select 6, pg_temp.push(pg_temp.u('plus'), jsonb_build_array(
  pg_temp.up('items', pg_temp.u('p1'), '{"title":"still editable"}', 1764000000001),
  pg_temp.appt('p13', now() + interval '3 days')));
select is((select array_agg(x->>'status' order by o) from r, jsonb_array_elements(res) with ordinality t(x, o) where n = 6),
  array['ok', 'quota_exceeded'], 'hạ gói: sửa được dữ liệu cũ, không tạo thêm');
update public.subscriptions set status = 'grace', current_period_end = now() - interval '1 day' where user_id = pg_temp.u('plus');
select is(app.effective_plan(pg_temp.u('plus')), 'plus', 'grace period vẫn giữ quyền Plus');

-- Chuỗi lặp: Free 5.
select pg_temp.push(pg_temp.u('free'), (select jsonb_agg(m order by g, k) from generate_series(1, 6) g,
  lateral (values
    (1, pg_temp.up('items', pg_temp.u('h' || g), jsonb_build_object('kind', 'habit', 'title', 'h' || g))),
    (2, pg_temp.up('recurrences', pg_temp.u('h' || g), jsonb_build_object('kind', 'rrule', 'rrule', 'FREQ=WEEKLY;BYDAY=MO', 'dtstart', now())))
  ) v(k, m)));
select is(app.usage_for(pg_temp.u('free'), 'max_recurring_series'), 5, 'chuỗi lặp thứ 6 bị từ chối');

-- Nhắc/ngày: 3 chuỗi "uống thuốc 3 lần/ngày" = 9; chuỗi thứ 4 làm ngày cao nhất lên 12 > 10.
select pg_temp.mk_user(pg_temp.u('meds'), 'Europe/Berlin', 'DE', 'de-DE');
select pg_temp.push(pg_temp.u('meds'), (select jsonb_agg(m order by g, k) from generate_series(1, 3) g,
  lateral (values
    (1, pg_temp.up('items', pg_temp.u('m' || g), jsonb_build_object('kind', 'habit', 'title', 'med' || g, 'starts_at', now()))),
    (2, pg_temp.up('recurrences', pg_temp.u('m' || g), jsonb_build_object('kind', 'rrule', 'rrule', 'FREQ=DAILY;BYHOUR=8,13,20', 'dtstart', now()))),
    (3, pg_temp.up('reminders', pg_temp.u('mr' || g), jsonb_build_object('item_id', pg_temp.u('m' || g), 'trigger_kind', 'offset', 'offset_minutes', 0)))
  ) v(k, m)));
select is(app.usage_for(pg_temp.u('meds'), 'max_reminders_per_day'), 9, 'đếm nhắc/ngày gồm lần lặp và BYHOUR');
insert into r select 7, pg_temp.push(pg_temp.u('meds'), jsonb_build_array(
  pg_temp.up('items', pg_temp.u('m4'), jsonb_build_object('kind', 'habit', 'title', 'med4', 'starts_at', now())),
  pg_temp.up('recurrences', pg_temp.u('m4'), jsonb_build_object('kind', 'rrule', 'rrule', 'FREQ=DAILY;BYHOUR=8,13,20', 'dtstart', now())),
  pg_temp.up('reminders', pg_temp.u('mr4'), jsonb_build_object('item_id', pg_temp.u('m4'), 'trigger_kind', 'offset', 'offset_minutes', 0))));
select is((select res->2->'details'->>'key' from r where n = 7), 'max_reminders_per_day', 'nhắc thứ 12 trong ngày bị từ chối');

-- List: Inbox không tính; Free 5.
select pg_temp.push(pg_temp.u('free'), (select jsonb_agg(pg_temp.up('lists', pg_temp.u('l' || g), jsonb_build_object('name', 'L' || g))) from generate_series(1, 6) g));
select is(app.usage_for(pg_temp.u('free'), 'max_lists'), 5, 'list thứ 6 bị từ chối, Inbox không tính');

-- Smart import: Free 10/tháng; failed, ics không tính.
select pg_temp.push(pg_temp.u('meds'), (select jsonb_agg(pg_temp.up('imports', pg_temp.u('im' || g), jsonb_build_object('kind', 'image', 'status', 'committed'))) from generate_series(1, 10) g));
insert into r select 8, pg_temp.push(pg_temp.u('meds'), jsonb_build_array(
  pg_temp.up('imports', pg_temp.u('im-ics'), '{"kind":"ics","status":"committed"}'),
  pg_temp.up('imports', pg_temp.u('im-fail'), '{"kind":"pdf","status":"failed"}'),
  pg_temp.up('imports', pg_temp.u('im11'), '{"kind":"pdf","status":"reviewing"}')));
select is((select array_agg(x->>'status' order by o) from r, jsonb_array_elements(res) with ordinality t(x, o) where n = 8),
  array['ok', 'ok', 'quota_exceeded'], 'import thứ 11 bị chặn; .ics và import thất bại không tính');
insert into r select 9, pg_temp.push(pg_temp.u('meds'), jsonb_build_array(
  pg_temp.up('imports', pg_temp.u('im-fail'), '{"status":"committed"}', 1764000000005)));
select is((select res->0->>'status' from r where n = 9), 'quota_exceeded', 'không lách bằng cách tạo failed rồi sửa thành committed');

-- Chuyến đi: Free 1 đang/sắp diễn ra.
insert into r select 10, pg_temp.push(pg_temp.u('meds'), jsonb_build_array(
  pg_temp.up('trips', pg_temp.u('t-old'), jsonb_build_object('title', 'Old', 'starts_on', current_date - 30, 'ends_on', current_date - 20)),
  pg_temp.up('trips', pg_temp.u('t1'), jsonb_build_object('title', 'Rome', 'starts_on', current_date + 10, 'ends_on', current_date + 15)),
  pg_temp.up('trips', pg_temp.u('t2'), jsonb_build_object('title', 'Tokyo', 'starts_on', current_date + 40, 'ends_on', current_date + 45))));
select is((select array_agg(x->>'status' order by o) from r, jsonb_array_elements(res) with ordinality t(x, o) where n = 10),
  array['ok', 'ok', 'quota_exceeded'], 'chuyến đi đã qua không tính; chuyến thứ 2 bị chặn');

select is((pg_temp.quota(pg_temp.u('meds'))->'usage'->>'smart_imports_per_month')::int, 10, 'quota_status trả mức dùng');

select * from finish();
rollback;
