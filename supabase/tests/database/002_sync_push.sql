-- sync_push: insert, LWW theo trường, xung đột notes, tombstone, cách ly user, lỗi từng mutation.
begin;
\ir _helpers.psql
select plan(20);

select pg_temp.mk_user(pg_temp.u('alice'));
select pg_temp.mk_user(pg_temp.u('bob'));

create temp table r (n int, res jsonb);
grant all on r to authenticated;

-- 1. Insert
insert into r select 1, pg_temp.push(pg_temp.u('alice'), jsonb_build_array(
  pg_temp.up('items', pg_temp.u('i1'), '{"kind":"task","title":"Buy milk","notes":"2L"}', 1000)));
select is((select res->0->>'status' from r where n = 1), 'ok', 'insert trả ok');
select ok((select (res->0->>'version')::bigint > 0 from r where n = 1), 'insert trả version');
select is((select user_id from public.items where id = pg_temp.u('i1')), pg_temp.u('alice'), 'user_id lấy từ JWT');

-- 2. LWW theo trường: title clock cũ hơn thua, priority clock mới hơn thắng.
insert into r select 2, pg_temp.push(pg_temp.u('alice'), jsonb_build_array(jsonb_build_object(
  'table', 'items', 'id', pg_temp.u('i1'), 'op', 'upsert',
  'payload', '{"title":"Old title","priority":2}'::jsonb,
  'field_clock', jsonb_build_object('title', pg_temp.clk(500, 'dev-b'), 'priority', pg_temp.clk(2000, 'dev-b')))), 'dev-b');
select is((select title from public.items where id = pg_temp.u('i1')), 'Buy milk', 'trường có clock cũ hơn bị bỏ qua');
select is((select priority from public.items where id = pg_temp.u('i1')), 2::smallint, 'trường có clock mới hơn được ghi');
select is((select res->0->'server_row'->>'title' from r where n = 2), 'Buy milk', 'server_row trả giá trị thắng để client sửa bản local');

-- 3. Cùng clock: không ghi, version giữ nguyên.
insert into r select 3, pg_temp.push(pg_temp.u('alice'), jsonb_build_array(
  pg_temp.up('items', pg_temp.u('i1'), '{"title":"Same clock"}', 1000)));
select is((select res->0->>'version' from r where n = 3), (select res->0->>'version' from r where n = 2),
  'clock bằng nhau không tạo version mới');

-- 4. notes sửa đồng thời từ 2 bản gốc khác nhau: conflict, không ghi đè.
insert into r select 4, pg_temp.push(pg_temp.u('alice'), jsonb_build_array(jsonb_build_object(
  'table', 'items', 'id', pg_temp.u('i1'), 'op', 'upsert', 'payload', '{"notes":"3L from phone B"}'::jsonb,
  'field_clock', jsonb_build_object('notes', pg_temp.clk(3000, 'dev-b')),
  'base_clock', jsonb_build_object('notes', pg_temp.clk(100, 'dev-b')))));
select is((select res->0->>'status' from r where n = 4), 'conflict', 'notes đồng thời trả conflict');
select is((select notes from public.items where id = pg_temp.u('i1')), '2L', 'notes không bị ghi đè khi conflict');

-- 5. notes sửa từ đúng bản hiện tại: ghi bình thường.
insert into r select 5, pg_temp.push(pg_temp.u('alice'), jsonb_build_array(jsonb_build_object(
  'table', 'items', 'id', pg_temp.u('i1'), 'op', 'upsert', 'payload', '{"notes":"3L"}'::jsonb,
  'field_clock', jsonb_build_object('notes', pg_temp.clk(3000, 'dev-b')),
  'base_clock', jsonb_build_object('notes', pg_temp.clk(1000, 'dev-test')))));
select is((select notes from public.items where id = pg_temp.u('i1')), '3L', 'notes ghi khi base_clock khớp');

-- 6. Cách ly: Bob không sửa được item của Alice, không trỏ được tới list của Alice.
insert into r select 6, pg_temp.push(pg_temp.u('bob'), jsonb_build_array(
  pg_temp.up('items', pg_temp.u('i1'), '{"title":"pwned"}', 9999999999999)));
select is((select res->0->>'error' from r where n = 6), 'not_found', 'sửa item người khác: not_found');
select is((select title from public.items where id = pg_temp.u('i1')), 'Buy milk', 'item của Alice không đổi');
insert into r select 7, pg_temp.push(pg_temp.u('bob'), jsonb_build_array(pg_temp.up('items', pg_temp.u('b1'),
  jsonb_build_object('kind', 'task', 'title', 'x', 'list_id', md5(pg_temp.u('alice')::text || ':inbox')::uuid))));
select is((select res->0->>'error' from r where n = 7), '23503', 'không trỏ được tới list của user khác (FK kèm user_id)');
insert into r select 8, pg_temp.push(pg_temp.u('bob'), jsonb_build_array(pg_temp.up('items', pg_temp.u('b2'),
  jsonb_build_object('kind', 'task', 'title', 'x', 'user_id', pg_temp.u('alice')))));
select is((select user_id from public.items where id = pg_temp.u('b2')), pg_temp.u('bob'), 'user_id trong payload bị bỏ qua');

-- 7. Một mutation lỗi không làm hỏng mutation khác trong batch.
insert into r select 9, pg_temp.push(pg_temp.u('alice'), jsonb_build_array(
  pg_temp.up('items', pg_temp.u('bad'), '{"kind":"nope","title":"x"}'),
  pg_temp.up('items', pg_temp.u('i2'), '{"kind":"task","title":"Second"}'),
  jsonb_build_object('table', 'secrets', 'id', pg_temp.u('z'), 'op', 'upsert', 'payload', '{}'::jsonb)));
select is((select array_agg(x->>'status' order by o) from r, jsonb_array_elements(res) with ordinality t(x, o) where n = 9),
  array['invalid', 'ok', 'invalid'], 'lỗi từng mutation độc lập');

-- 8. Xóa item: tombstone dây chuyền cho reminder; upsert sau khi xóa trả conflict.
select pg_temp.push(pg_temp.u('alice'), jsonb_build_array(
  pg_temp.up('reminders', pg_temp.u('r1'), jsonb_build_object('item_id', pg_temp.u('i2'), 'trigger_kind', 'absolute', 'at', now() + interval '1 day'))));
select pg_temp.push(pg_temp.u('alice'), jsonb_build_array(pg_temp.del('items', pg_temp.u('i2'))));
select ok((select deleted_at is not null from public.reminders where id = pg_temp.u('r1')), 'xóa item thì reminder thành tombstone');
insert into r select 10, pg_temp.push(pg_temp.u('alice'), jsonb_build_array(
  pg_temp.up('items', pg_temp.u('i2'), '{"title":"revive"}', 9000000000000)));
select is((select res->0->>'error' from r where n = 10), 'deleted', 'sửa item đã xóa: conflict deleted');

-- 9. occurrence_log khóa (item_id, occurrence_at): 2 thiết bị ghi cùng lần lặp ra 1 hàng.
select pg_temp.push(pg_temp.u('alice'), jsonb_build_array(
  jsonb_build_object('table', 'occurrence_log', 'op', 'upsert',
    'payload', jsonb_build_object('item_id', pg_temp.u('i1'), 'occurrence_at', '2026-12-01T08:00:00Z', 'status', 'done'),
    'field_clock', jsonb_build_object('status', pg_temp.clk(1000, 'a'))),
  jsonb_build_object('table', 'occurrence_log', 'op', 'upsert',
    'payload', jsonb_build_object('item_id', pg_temp.u('i1'), 'occurrence_at', '2026-12-01T08:00:00Z', 'status', 'skipped'),
    'field_clock', jsonb_build_object('status', pg_temp.clk(2000, 'b')))));
select is((select count(*) || ':' || max(status) from public.occurrence_log where item_id = pg_temp.u('i1')), '1:skipped',
  'occurrence_log gộp theo khóa, clock mới thắng');

-- 10. Lỗi cấp batch.
select throws_ok($$ select pg_temp.push(pg_temp.u('alice'), (select jsonb_agg(pg_temp.up('items', gen_random_uuid(), '{"kind":"task","title":"x"}')) from generate_series(1, 201))) $$,
  '22023', null, 'batch > 200 mutation bị từ chối');
select throws_ok($$ select public.sync_push('d', '[]'::jsonb) from (select set_config('request.jwt.claims', '', true)) s $$,
  '28000', null, 'không có JWT: unauthenticated');

select * from finish();
rollback;
