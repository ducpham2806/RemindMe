-- Dữ liệu tham chiếu gói. Nguồn chuẩn: docs/product/pricing-entitlements.md §2 (đổi ở đó trước, rồi viết migration mới).
-- -1 = không giới hạn; feature_* là cấp 0/1/2.

insert into public.plans (id, name) values ('free', 'Free'), ('plus', 'Plus');

insert into public.plan_products (plan_id, period, store, product_id) values
  ('plus', 'P1M', 'app_store', 'remindme_plus_monthly'),
  ('plus', 'P3M', 'app_store', 'remindme_plus_quarterly'),
  ('plus', 'P1Y', 'app_store', 'remindme_plus_yearly'),
  -- Play: 1 subscription, 3 base plan
  ('plus', 'P1M', 'play', 'remindme_plus'),
  ('plus', 'P3M', 'play', 'remindme_plus'),
  ('plus', 'P1Y', 'play', 'remindme_plus');

insert into public.plan_entitlements (plan_id, key, value)
select p.plan_id, v.key, case p.plan_id when 'free' then v.free else v.plus end
from (values
  ('max_reminders_per_day',      10,   -1),
  ('max_recurring_series',        5,   -1),
  ('max_active_appointments',    10,   -1),
  ('max_active_trips',            1,   -1),
  ('smart_imports_per_month',    10,   -1),
  ('voice_input',                -1,   -1),
  ('max_import_pages',           20,  200),
  ('max_originals_mb',            0, 1024),
  ('max_lists',                   5,   -1),
  ('calendar_sync_accounts',      1,    5),
  ('feature_watch_app',           1,    2),
  ('feature_ics_feed',            0,    1),
  ('feature_location_reminder',   0,    1),
  ('feature_enhanced_voice',      1,    1),
  ('feature_flight_status',       0,    1),
  ('feature_gmail_scan',          0,    1),
  ('feature_messaging_channel',   0,    1),
  ('feature_alt_calendars',       1,    1),
  ('feature_themes',              0,    1)
) as v(key, free, plus)
cross join (values ('free'), ('plus')) as p(plan_id);
