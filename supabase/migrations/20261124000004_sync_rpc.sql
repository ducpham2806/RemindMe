-- RPC đồng bộ (ADR-012, docs/architecture/api-spec.md §1).
-- field_clock: HLC dạng chuỗi so sánh được theo thứ tự byte (collate "C"):
--   '<epoch_ms 13 chữ số>:<counter 4 chữ số>:<device_id>'   ví dụ '1764000000000:0001:ios-7f3a'
-- Trường nào có clock lớn hơn thì thắng (LWW theo trường). Thiếu clock = '' (thua mọi clock có sẵn).

create function app.writable_cols(p_table text) returns text[]
language sql stable set search_path = '' as $$
  select array_agg(a.attname::text order by a.attnum)
  from pg_attribute a
  where a.attrelid = ('public.' || quote_ident(p_table))::regclass
    and a.attnum > 0 and not a.attisdropped
    and a.attname not in ('user_id', 'version', 'updated_at', 'deleted_at', 'device_id', 'field_clock', 'created_at')
$$;

create function app.result(p_table text, p_key jsonb, p_status text, p_row jsonb default null,
                           p_error text default null, p_details jsonb default null) returns jsonb
language sql immutable set search_path = '' as $$
  select jsonb_strip_nulls(jsonb_build_object(
    'table', p_table, 'id', coalesce(p_key->'id', p_key->'item_id'), 'key', p_key,
    'status', p_status, 'version', p_row->'version', 'server_row', p_row,
    'error', p_error, 'details', p_details))
$$;

-- Áp dụng 1 mutation trong subtransaction riêng: lỗi/quota của 1 mutation không làm hỏng cả batch.
create function app.apply_mutation(p_uid uuid, p_device text, m jsonb) returns jsonb
language plpgsql set search_path = '' as $$
declare
  v_table text := m->>'table';
  v_op text := coalesce(m->>'op', 'upsert');
  v_payload jsonb := coalesce(m->'payload', '{}');
  v_clock jsonb := coalesce(m->'field_clock', '{}');
  v_base jsonb := m->'base_clock';
  cfg app.sync_tables;
  v_cols text[];
  v_key jsonb;
  v_keyexpr text;
  v_keysel text;
  v_existing jsonb;
  v_row jsonb;
  v_win text[] := '{}';
  v_winclock jsonb := '{}';
  v_conflict boolean := false;
  c text; inc text; ex text;
  v_limits jsonb := '{}';
  v_before jsonb := '{}';
  k text; lim int; used_after int;
  v_q jsonb;
  v_parent_status text;
  v_insert_cols text[];
begin
  select * into cfg from app.sync_tables where name = v_table;
  if not found then
    return app.result(v_table, jsonb_build_object('id', m->'id'), 'invalid', null, 'unknown_table');
  end if;
  if v_op not in ('upsert', 'delete') or jsonb_typeof(v_payload) <> 'object' or jsonb_typeof(v_clock) <> 'object' then
    return app.result(v_table, jsonb_build_object('id', m->'id'), 'invalid', null, 'malformed_mutation');
  end if;

  v_key := case
    when cfg.key_cols = '{id}' then jsonb_build_object('id', m->'id')
    when cfg.key_cols = '{item_id}' then jsonb_build_object('item_id', coalesce(v_payload->'item_id', m->'id'))
    else jsonb_build_object('item_id', v_payload->'item_id', 'occurrence_at', v_payload->'occurrence_at')
  end;
  if exists (select 1 from jsonb_each(v_key) e where e.value is null or e.value = 'null'::jsonb) then
    return app.result(v_table, v_key, 'invalid', null, 'missing_key');
  end if;
  v_payload := v_payload || v_key;
  select string_agg(format('t.%I', x), ','), string_agg(format('r.%I', x), ',')
    into v_keyexpr, v_keysel from unnest(cfg.key_cols) x;
  v_cols := app.writable_cols(v_table);

  begin
    -- Mức dùng trước khi ghi, chỉ cho các key có giới hạn.
    foreach k in array cfg.quota_keys loop
      lim := app.limit_for(p_uid, k);
      if lim <> -1 then
        v_limits := v_limits || jsonb_build_object(k, lim);
        v_before := v_before || jsonb_build_object(k, app.usage_for(p_uid, k));
      end if;
    end loop;

    execute format(
      'select to_jsonb(t) from public.%I t where (%s) = (select %s from jsonb_populate_record(null::public.%I, $1) r) for update',
      v_table, v_keyexpr, v_keysel, v_table) into v_existing using v_payload;

    if v_existing is not null and (v_existing->>'user_id')::uuid <> p_uid then
      return app.result(v_table, v_key, 'invalid', null, 'not_found');
    end if;

    if v_existing is null then
      if v_op = 'delete' then
        return app.result(v_table, v_key, 'ok');
      end if;
      select array_agg(x) into v_win from unnest(v_cols) x where v_payload ? x;
      select coalesce(jsonb_object_agg(x, v_clock->x), '{}') into v_winclock
        from unnest(v_win) x where v_clock ? x and not x = any(cfg.key_cols);
      v_insert_cols := v_win || array['user_id', 'device_id', 'field_clock'];
      execute format(
        'insert into public.%I as t (%s) select %s from jsonb_populate_record(null::public.%I, $1) r returning to_jsonb(t.*)',
        v_table,
        (select string_agg(format('%I', x), ',') from unnest(v_insert_cols) x),
        (select string_agg(format('r.%I', x), ',') from unnest(v_insert_cols) x),
        v_table)
      into v_row
      using v_payload || jsonb_build_object('user_id', p_uid, 'device_id', p_device, 'field_clock', v_winclock);
    else
      if v_existing->>'deleted_at' is not null then
        return app.result(v_table, v_key, 'conflict', v_existing, 'deleted');
      end if;

      if v_op = 'delete' then
        execute format(
          'update public.%I t set deleted_at = now(), device_id = $2
             where (%s) = (select %s from jsonb_populate_record(null::public.%I, $1) r) returning to_jsonb(t.*)',
          v_table, v_keyexpr, v_keysel, v_table) into v_row using v_payload, p_device;
        if v_table = 'items' then
          update public.reminders set deleted_at = now(), device_id = p_device
            where item_id = (v_key->>'id')::uuid and deleted_at is null;
          update public.recurrences set deleted_at = now(), device_id = p_device
            where item_id = (v_key->>'id')::uuid and deleted_at is null;
          update public.booking_details set deleted_at = now(), device_id = p_device
            where item_id = (v_key->>'id')::uuid and deleted_at is null;
          update public.occurrence_log set deleted_at = now(), device_id = p_device
            where item_id = (v_key->>'id')::uuid and deleted_at is null;
        end if;
        return app.result(v_table, v_key, 'ok', v_row);
      end if;

      foreach c in array v_cols loop
        continue when not (v_payload ? c) or c = any(cfg.key_cols);
        inc := coalesce(v_clock->>c, '');
        ex := coalesce(v_existing->'field_clock'->>c, '');
        -- notes: 2 thiết bị cùng sửa từ 1 bản gốc thì không tự chọn, trả conflict để app hiện màn chọn bản (UX §3.6).
        if c = 'notes' and v_base ? 'notes' and coalesce(v_base->>'notes', '') <> ex
           and (v_existing->'notes') is distinct from (v_payload->'notes') then
          v_conflict := true;
          continue;
        end if;
        if (inc collate "C") > (ex collate "C") then
          v_win := v_win || c;
          v_winclock := v_winclock || jsonb_build_object(c, inc);
        end if;
      end loop;

      if coalesce(array_length(v_win, 1), 0) = 0 then
        v_row := v_existing;
      else
        execute format(
          'update public.%I t set (%s) = (select %s from jsonb_populate_record(null::public.%I, $1) r),
                  device_id = $2, field_clock = t.field_clock || $3
             where (%s) = (select %s from jsonb_populate_record(null::public.%I, $1) r) returning to_jsonb(t.*)',
          v_table,
          (select string_agg(format('%I', x), ',') from unnest(v_win) x),
          (select string_agg(format('r.%I', x), ',') from unnest(v_win) x),
          v_table, v_keyexpr, v_keysel, v_table)
        into v_row using v_payload, p_device, v_winclock;
      end if;
    end if;

    -- Kiểm quota: chỉ chặn khi vượt giới hạn VÀ thay đổi này làm tăng mức dùng (hạ gói không khóa dữ liệu cũ).
    for k, lim in select e.key, e.value::int from jsonb_each_text(v_limits) e loop
      used_after := app.usage_for(p_uid, k);
      if used_after > lim and used_after > (v_before->>k)::int then
        v_q := jsonb_build_object('key', k, 'limit', lim, 'used', (v_before->>k)::int);
        -- Item tạo offline ở pending_quota: không bỏ dữ liệu, chuyển sang archived/quota.
        if v_table = 'items' and v_row->>'status' = 'pending_quota' then
          update public.items i set status = 'archived', archived_reason = 'quota'
            where i.id = (v_row->>'id')::uuid returning to_jsonb(i.*) into v_row;
          return app.result(v_table, v_key, 'quota_exceeded', v_row, 'quota_exceeded', v_q);
        end if;
        if cfg.parent_item_col is not null then
          select i.status into v_parent_status from public.items i
            where i.id = (v_payload->>cfg.parent_item_col)::uuid;
          if v_parent_status = 'pending_quota' then
            update public.items i set status = 'archived', archived_reason = 'quota'
              where i.id = (v_payload->>cfg.parent_item_col)::uuid;
            return app.result(v_table, v_key, 'quota_exceeded', v_row, 'quota_exceeded',
                              v_q || jsonb_build_object('archived_item_id', v_payload->>cfg.parent_item_col));
          end if;
        end if;
        raise exception 'quota_exceeded' using errcode = 'RMQ01';
      end if;
    end loop;

    if v_conflict then
      return app.result(v_table, v_key, 'conflict', v_row, 'notes_conflict');
    end if;
    return app.result(v_table, v_key, 'ok', v_row);
  exception
    when sqlstate 'RMQ01' then
      return app.result(v_table, v_key, 'quota_exceeded', null, 'quota_exceeded', v_q);
    when others then
      return app.result(v_table, v_key, 'invalid', null, sqlstate, jsonb_build_object('message', sqlerrm));
  end;
end $$;

-- Đường ghi duy nhất của app.
create function public.sync_push(device_id text, mutations jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_device text := $1;
  v_muts jsonb := $2;
  m jsonb;
  v_res jsonb;
  v_results jsonb := '[]';
  v_touched uuid[] := '{}';
  v_promoted jsonb;
begin
  if v_uid is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;
  if not exists (select 1 from public.profiles p where p.id = v_uid) then
    raise exception 'profile_missing: call profile_init first' using errcode = 'P0002';
  end if;
  if v_muts is null or jsonb_typeof(v_muts) <> 'array' or jsonb_array_length(v_muts) > 200 then
    raise exception 'invalid: mutations must be an array of at most 200' using errcode = '22023';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(v_uid::text, 42));

  for m in select value from jsonb_array_elements(v_muts) loop
    v_res := app.apply_mutation(v_uid, v_device, m);
    v_results := v_results || jsonb_build_array(v_res);
    if v_res->>'table' = 'items' and v_res->>'status' = 'ok' and v_res->'server_row'->>'status' = 'pending_quota' then
      v_touched := v_touched || (v_res->>'id')::uuid;
    end if;
  end loop;

  -- pending_quota còn lại sau cả batch (không bị con nào làm vượt quota) thì chính thức mở.
  if array_length(v_touched, 1) > 0 then
    with promoted as (
      update public.items i set status = 'open'
        where i.user_id = v_uid and i.status = 'pending_quota' and i.id = any(v_touched)
        returning i.id, to_jsonb(i.*) as row
    )
    select coalesce(jsonb_object_agg(p.id::text, p.row), '{}') into v_promoted from promoted p;

    select jsonb_agg(case
             when r->>'table' = 'items' and v_promoted ? (r->>'id')
               then r || jsonb_build_object('server_row', v_promoted->(r->>'id'), 'version', v_promoted->(r->>'id')->'version')
             else r end order by ord)
      into v_results
      from jsonb_array_elements(v_results) with ordinality as x(r, ord);
  end if;

  return v_results;
end $$;

-- Kéo thay đổi có version > since, gồm tombstone. Trang tối đa 1000 hàng.
create function public.sync_pull(since bigint default 0, lim int default 500) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_since bigint := coalesce($1, 0);
  v_lim int := least(greatest(coalesce($2, 500), 1), 1000);
  v_union text;
  v_res jsonb;
begin
  if v_uid is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;
  select string_agg(format(
    '(select %L as tbl, t.version, to_jsonb(t) as row from public.%I t
       where t.user_id = $1 and t.version > $2 order by t.version limit $3 + 1)', s.name, s.name), ' union all ')
    into v_union from app.sync_tables s;
  execute format($q$
    with u as (%s),
    page as (select * from u order by version limit $3)
    select jsonb_build_object(
      'rows', coalesce((select jsonb_object_agg(g.tbl, g.rows)
                        from (select tbl, jsonb_agg(row order by version) as rows from page group by tbl) g), '{}'),
      'next_since', coalesce((select max(version) from page), $2),
      'has_more', (select count(*) from u) > $3)
  $q$, v_union) into v_res using v_uid, v_since, v_lim;
  return v_res;
end $$;

-- Gói, giới hạn, mức dùng, tính năng cho app (cache 24h phía client, ADR-008).
create function public.quota_status() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_plan text;
  v_limits jsonb := '{}';
  v_usage jsonb := '{}';
  v_features jsonb := '{}';
  e record;
begin
  if v_uid is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;
  v_plan := app.effective_plan(v_uid);
  for e in
    select k.key, app.limit_for(v_uid, k.key) as value
    from (select distinct key from public.plan_entitlements) k
  loop
    if e.key like 'feature\_%' then
      v_features := v_features || jsonb_build_object(e.key, e.value);
    else
      v_limits := v_limits || jsonb_build_object(e.key, e.value);
    end if;
  end loop;
  for e in select distinct unnest(quota_keys) as key from app.sync_tables loop
    v_usage := v_usage || jsonb_build_object(e.key, app.usage_for(v_uid, e.key));
  end loop;
  return jsonb_build_object(
    'plan', v_plan,
    'period_end', (select s.current_period_end from public.subscriptions s where s.user_id = v_uid and v_plan <> 'free'),
    'limits', v_limits, 'usage', v_usage, 'features', v_features);
end $$;

-- Tạo profile lúc onboarding (locale/region/tz lấy từ máy, không có giá trị mặc định).
-- Tạo luôn list Inbox với id xác định md5(uid || ':inbox'), để máy offline tự tính ra cùng id, không sinh Inbox trùng.
create function public.profile_init(ui_locale text, region text, home_tz text, display_name text default null)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_inbox uuid;
begin
  if v_uid is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;
  insert into public.profiles (id, display_name, ui_locale, region, home_tz, inbound_email_token)
    values (v_uid, $4, $1, upper($2), $3, encode(extensions.gen_random_bytes(12), 'hex'))
    on conflict (id) do nothing;
  v_inbox := md5(v_uid::text || ':inbox')::uuid;
  insert into public.lists (id, user_id, name, is_inbox, device_id)
    values (v_inbox, v_uid, 'inbox', true, 'server')
    on conflict (id) do nothing;
  return (select to_jsonb(p) - 'calendar_feed_token' from public.profiles p where p.id = v_uid);
end $$;

revoke all on function public.sync_push(text, jsonb), public.sync_pull(bigint, int), public.quota_status(),
  public.profile_init(text, text, text, text) from public, anon;
grant execute on function public.sync_push(text, jsonb), public.sync_pull(bigint, int), public.quota_status(),
  public.profile_init(text, text, text, text) to authenticated;
revoke all on all functions in schema app from public;
