-- Schema lõi. Nguồn chuẩn tên bảng/cột: docs/architecture/data-model.md §3.
-- SYNC_COLS = updated_at, version, deleted_at, device_id, field_clock (version do trigger gán, xem migration 02).

create schema if not exists app;            -- hàm nội bộ, PostgREST không expose
revoke all on schema app from public;

create sequence app.sync_version as bigint;

-- Kiểm tên múi giờ IANA (dùng trong CHECK; Postgres không bắt buộc hàm immutable ở CHECK).
create function app.is_valid_tz(p_tz text) returns boolean
language plpgsql stable set search_path = '' as $$
begin
  if p_tz is null then return true; end if;
  perform now() at time zone p_tz;
  return true;
exception when others then
  return false;
end $$;

create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  display_name text,
  ui_locale text not null check (ui_locale ~ '^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$'),
  region text not null check (region ~ '^[A-Z]{2}$'),
  home_tz text not null check (app.is_valid_tz(home_tz)),
  voice_locales text[] not null default '{}',
  calendar_systems text[] not null default '{}'
    check (calendar_systems <@ array['lunar_vi','lunar_zh','lunar_ko','hijri']),
  inbound_email_token text unique,
  calendar_feed_token text unique,
  settings jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table public.lists (
  id uuid primary key,
  user_id uuid not null references public.profiles on delete cascade,
  name text not null,
  color text, icon text, sort_order int,
  is_inbox bool not null default false,
  updated_at timestamptz not null default now(), version bigint not null default 0,
  deleted_at timestamptz, device_id text, field_clock jsonb not null default '{}',
  unique (id, user_id)
);

create table public.trips (
  id uuid primary key,
  user_id uuid not null references public.profiles on delete cascade,
  title text not null, destination text, starts_on date, ends_on date, cover_url text,
  updated_at timestamptz not null default now(), version bigint not null default 0,
  deleted_at timestamptz, device_id text, field_clock jsonb not null default '{}',
  unique (id, user_id),
  check (ends_on is null or starts_on is null or ends_on >= starts_on)
);

create table public.imports (
  id uuid primary key,
  user_id uuid not null references public.profiles on delete cascade,
  kind text not null check (kind in ('image','pdf','xlsx','md','email','voice','text','ics','pkpass')),
  sha256 text, mime text, bytes int,
  status text not null default 'reviewing' check (status in ('reviewing','committed','discarded','failed')),
  doc_type text, doc_language text, template_id text, template_version int,
  tier_used text check (tier_used in ('t0','t1t2','t3_apple','t3_gemini','t4')),
  original_path text,
  error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(), version bigint not null default 0,
  deleted_at timestamptz, device_id text, field_clock jsonb not null default '{}',
  unique (id, user_id)
);

create table public.items (
  id uuid primary key,
  user_id uuid not null references public.profiles on delete cascade,
  list_id uuid, trip_id uuid, import_id uuid,
  kind text not null check (kind in ('task','event','appointment','booking','habit')),
  title text not null,
  notes text,
  status text not null default 'open' check (status in ('open','done','cancelled','archived','pending_quota')),
  archived_reason text check (archived_reason in ('past','user','quota')),
  priority smallint not null default 0 check (priority between 0 and 3),
  starts_at timestamptz, ends_at timestamptz,
  all_day bool not null default false, start_date date, end_date date,
  tz text check (app.is_valid_tz(tz)),
  end_tz text check (app.is_valid_tz(end_tz)),
  time_mode text not null default 'fixed' check (time_mode in ('fixed','floating')),
  location jsonb,
  tags text[] not null default '{}',
  source text not null default 'manual' check (source in
    ('manual','voice','image','pdf','xlsx','md','email','gmail','gcal','gtasks','notion','mstodo','ics','pkpass')),
  source_ref text,
  checklist jsonb,
  completed_at timestamptz,
  updated_at timestamptz not null default now(), version bigint not null default 0,
  deleted_at timestamptz, device_id text, field_clock jsonb not null default '{}',
  unique (id, user_id),
  -- Khóa ngoại kèm user_id: không thể trỏ tới list/trip/import của người khác.
  foreign key (list_id, user_id) references public.lists (id, user_id),
  foreign key (trip_id, user_id) references public.trips (id, user_id),
  foreign key (import_id, user_id) references public.imports (id, user_id),
  check (ends_at is null or starts_at is null or ends_at >= starts_at),
  check (end_date is null or start_date is null or end_date >= start_date),
  check ((status = 'archived') = (archived_reason is not null))
);
create unique index items_source_ref_uq on public.items (user_id, source, source_ref)
  where source_ref is not null and deleted_at is null;
create index items_user_starts_idx on public.items (user_id, starts_at) where deleted_at is null;

create table public.recurrences (
  item_id uuid primary key,
  user_id uuid not null references public.profiles on delete cascade,
  kind text not null check (kind in ('rrule','calendar','after_completion')),
  rrule text,
  calendar jsonb,
  interval_days int check (interval_days is null or interval_days > 0),
  workdays_region text check (workdays_region ~ '^[A-Z]{2}$'),
  dtstart timestamptz not null, until timestamptz, exdates timestamptz[] not null default '{}',
  updated_at timestamptz not null default now(), version bigint not null default 0,
  deleted_at timestamptz, device_id text, field_clock jsonb not null default '{}',
  foreign key (item_id, user_id) references public.items (id, user_id) on delete cascade,
  check (
    (kind = 'rrule' and rrule is not null) or
    (kind = 'calendar' and calendar ? 'system' and calendar->>'system' in ('lunar_vi','lunar_zh','lunar_ko','hijri')) or
    (kind = 'after_completion' and interval_days is not null)
  )
);

create table public.occurrence_log (
  item_id uuid not null,
  user_id uuid not null references public.profiles on delete cascade,
  occurrence_at timestamptz not null,
  status text not null check (status in ('done','skipped','snoozed')),
  updated_at timestamptz not null default now(), version bigint not null default 0,
  deleted_at timestamptz, device_id text, field_clock jsonb not null default '{}',
  primary key (item_id, occurrence_at),
  foreign key (item_id, user_id) references public.items (id, user_id) on delete cascade
);

create table public.reminders (
  id uuid primary key,
  user_id uuid not null references public.profiles on delete cascade,
  item_id uuid not null,
  trigger_kind text not null check (trigger_kind in ('absolute','offset','location')),
  at timestamptz,
  offset_minutes int,
  geofence jsonb,
  channel text[] not null default '{push}' check (channel <@ array['push','alarm','watch','email']),
  is_alarm bool not null default false,
  snoozed_until timestamptz,
  updated_at timestamptz not null default now(), version bigint not null default 0,
  deleted_at timestamptz, device_id text, field_clock jsonb not null default '{}',
  foreign key (item_id, user_id) references public.items (id, user_id) on delete cascade,
  check (
    (trigger_kind = 'absolute' and at is not null) or
    (trigger_kind = 'offset' and offset_minutes is not null) or
    (trigger_kind = 'location' and geofence is not null)
  )
);

create table public.booking_details (
  item_id uuid primary key,
  user_id uuid not null references public.profiles on delete cascade,
  booking_type text not null check (booking_type in
    ('flight','train','bus','hotel','car_rental','ferry','tour','restaurant','event_ticket','other')),
  provider text,
  confirmation_code text,
  carrier_code text, number text,
  origin jsonb, destination jsonb,
  seat text, class text,
  passengers jsonb,
  check_in_at timestamptz, check_out_at timestamptz,
  price jsonb,
  extraction_meta jsonb,
  updated_at timestamptz not null default now(), version bigint not null default 0,
  deleted_at timestamptz, device_id text, field_clock jsonb not null default '{}',
  foreign key (item_id, user_id) references public.items (id, user_id) on delete cascade
);

-- Chỉ mục kéo dữ liệu theo version cho sync_pull.
create index lists_sync_idx on public.lists (user_id, version);
create index trips_sync_idx on public.trips (user_id, version);
create index imports_sync_idx on public.imports (user_id, version);
create index items_sync_idx on public.items (user_id, version);
create index recurrences_sync_idx on public.recurrences (user_id, version);
create index occurrence_log_sync_idx on public.occurrence_log (user_id, version);
create index reminders_sync_idx on public.reminders (user_id, version);
create index booking_details_sync_idx on public.booking_details (user_id, version);
create index reminders_item_idx on public.reminders (item_id);

-- Bảng không đồng bộ qua sync_push.
create table public.mailbox_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles on delete cascade,
  storage_path text not null, bytes int, from_addr text, spf_dkim_pass bool,
  received_at timestamptz not null default now(), fetched_at timestamptz, expires_at timestamptz not null
);

create table public.integrations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles on delete cascade,
  provider text not null check (provider in ('google_calendar','google_tasks','microsoft','notion')),
  scopes text[], external_account text,
  token_ref text not null,
  sync_state jsonb, status text not null default 'active', updated_at timestamptz not null default now()
);

create table public.devices (
  id text primary key,
  user_id uuid not null references public.profiles on delete cascade,
  platform text check (platform in ('ios','android','watchos','wearos')),
  fcm_token text, app_version text, os_version text,
  tz text check (app.is_valid_tz(tz)), oem text, locale text,
  scheduled_until timestamptz,
  receives_reminders bool not null default true,
  last_seen_at timestamptz
);

-- Gói & quota. Giá trị seed: migration 05 (nguồn chuẩn: docs/product/pricing-entitlements.md §2).
create table public.plans (id text primary key, name text not null);
create table public.plan_products (
  plan_id text not null references public.plans,
  period text not null check (period in ('P1M','P3M','P1Y')),
  store text not null check (store in ('app_store','play','web')),
  product_id text not null,
  primary key (store, product_id, period)
);
create table public.plan_entitlements (
  plan_id text not null references public.plans,
  key text not null,
  value int not null check (value >= -1),
  primary key (plan_id, key)
);
create table public.subscriptions (
  user_id uuid primary key references public.profiles on delete cascade,
  plan_id text not null references public.plans,
  status text not null check (status in ('trial','active','cancelled','grace','billing_retry','paused','expired','refunded')),
  period text, store text, original_transaction_id text,
  current_period_end timestamptz,
  updated_at timestamptz not null default now()
);
create table public.usage_counters (
  user_id uuid not null references public.profiles on delete cascade,
  key text not null, period_start date not null, value int not null default 0,
  primary key (user_id, key, period_start)
);
