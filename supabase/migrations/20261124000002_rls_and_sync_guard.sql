-- RLS + chặn ghi trực tiếp (ADR-012). App chỉ ĐỌC bảng đồng bộ qua PostgREST; mọi ghi đi qua RPC sync_push.

-- Danh sách bảng đồng bộ và khóa của từng bảng. sync_push/sync_pull đọc cấu hình từ đây.
create table app.sync_tables (
  name text primary key,
  key_cols text[] not null,
  parent_item_col text,            -- cột trỏ về items (để xóa dây chuyền và xử lý pending_quota)
  quota_keys text[] not null default '{}'
);
insert into app.sync_tables (name, key_cols, parent_item_col, quota_keys) values
  ('lists',           '{id}',                    null,      '{max_lists}'),
  ('trips',           '{id}',                    null,      '{max_active_trips}'),
  ('imports',         '{id}',                    null,      '{smart_imports_per_month}'),
  ('items',           '{id}',                    null,      '{max_active_appointments,max_recurring_series,max_reminders_per_day}'),
  ('recurrences',     '{item_id}',               'item_id', '{max_recurring_series,max_reminders_per_day}'),
  ('occurrence_log',  '{item_id,occurrence_at}', 'item_id', '{}'),
  ('reminders',       '{id}',                    'item_id', '{max_reminders_per_day}'),
  ('booking_details', '{item_id}',               'item_id', '{}');

-- Gán version + updated_at cho MỌI lần ghi (kể cả từ worker/service role), sau khi khóa theo user.
-- Khóa advisory theo user tuần tự hóa các giao dịch ghi của cùng một user, nên version của một user
-- được cấp đúng thứ tự commit: sync_pull(since) không bỏ sót hàng do giao dịch commit muộn.
-- SECURITY DEFINER: worker (service_role) ghi được mà không cần quyền trên sequence trong schema app.
create function app.stamp_sync_cols() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  perform pg_advisory_xact_lock(hashtextextended(new.user_id::text, 42));
  new.version := nextval('app.sync_version');
  new.updated_at := now();
  return new;
end $$;

-- Lớp dự phòng: dù grant/RLS bị cấu hình sai, role của client vẫn không ghi thẳng được.
-- Bên trong sync_push (SECURITY DEFINER) current_user là owner nên đi qua.
create function app.block_client_writes() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user in ('anon', 'authenticated') then
    raise exception 'direct writes are not allowed, use sync_push' using errcode = '42501';
  end if;
  return coalesce(new, old);
end $$;

do $$
declare t text;
begin
  for t in select name from app.sync_tables loop
    execute format('create trigger stamp_sync_cols before insert or update on public.%I
                    for each row execute function app.stamp_sync_cols()', t);
    execute format('create trigger block_client_writes before insert or update or delete on public.%I
                    for each row execute function app.block_client_writes()', t);
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon, authenticated', t);
    execute format('grant select on public.%I to authenticated', t);
    execute format('create policy own_rows_select on public.%I for select to authenticated
                    using (user_id = (select auth.uid()))', t);
  end loop;
end $$;

-- profiles: đọc bản thân; sửa một số cột qua grant theo cột. Tạo qua RPC profile_init (migration 04).
alter table public.profiles enable row level security;
revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
grant update (display_name, ui_locale, region, home_tz, voice_locales, calendar_systems, settings)
  on public.profiles to authenticated;
create policy own_profile_select on public.profiles for select to authenticated using (id = (select auth.uid()));
create policy own_profile_update on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

-- CHECK múi giờ gọi app.is_valid_tz với quyền của người ghi: cấp đúng hàm này, không cấp gì khác trong schema app.
grant usage on schema app to authenticated, service_role;
grant execute on function app.is_valid_tz(text) to authenticated, service_role;

-- Chỉ đọc bản thân, chỉ worker (service role) ghi.
do $$
declare t text;
begin
  foreach t in array array['subscriptions','usage_counters','devices','mailbox_messages','integrations'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon, authenticated', t);
    execute format('grant select on public.%I to authenticated', t);
    execute format('create policy own_rows_select on public.%I for select to authenticated
                    using (user_id = (select auth.uid()))', t);
  end loop;
end $$;
-- integrations.token_ref chỉ là khóa Vault, nhưng vẫn không cần lộ ra client.
revoke select on public.integrations from authenticated;
grant select (id, user_id, provider, scopes, external_account, status, updated_at) on public.integrations to authenticated;

-- Dữ liệu tham chiếu gói: ai đăng nhập cũng đọc được (paywall hiển thị giới hạn).
do $$
declare t text;
begin
  foreach t in array array['plans','plan_products','plan_entitlements'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon, authenticated', t);
    execute format('grant select on public.%I to anon, authenticated', t);
    execute format('create policy read_all on public.%I for select to anon, authenticated using (true)', t);
  end loop;
end $$;

revoke all on sequence app.sync_version from public;
