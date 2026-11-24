-- RLS, quyền, chặn ghi trực tiếp (ADR-012).
begin;
\ir _helpers.psql
select plan(12);

select pg_temp.mk_user(pg_temp.u('alice'), 'Europe/London', 'GB', 'en-GB');
select pg_temp.mk_user(pg_temp.u('bob'), 'Asia/Ho_Chi_Minh', 'VN', 'vi-VN');
select pg_temp.push(pg_temp.u('alice'), jsonb_build_array(
  pg_temp.up('items', pg_temp.u('a-item-1'), '{"kind":"task","title":"Buy milk"}')));

select is((select count(*) from pg_tables where schemaname = 'public' and not rowsecurity), 0::bigint,
  'mọi bảng public đều bật RLS');

select is((select count(*) from pg_policies where schemaname = 'public'
            and tablename in (select name from app.sync_tables) and cmd <> 'SELECT'), 0::bigint,
  'bảng đồng bộ chỉ có policy SELECT');

select is((select region from public.profiles where id = pg_temp.u('alice')), 'GB', 'profile_init chuẩn hóa region');
select ok((select is_inbox from public.lists where id = md5(pg_temp.u('alice')::text || ':inbox')::uuid),
  'profile_init tạo Inbox với id xác định');

-- Từ đây đóng vai Alice qua PostgREST.
select pg_temp.claims(pg_temp.u('alice'));
set local role authenticated;

select throws_ok(
  $$ insert into public.items (id, user_id, kind, title) values (gen_random_uuid(), auth.uid(), 'task', 'x') $$,
  '42501', null, 'authenticated không INSERT thẳng vào items');
select throws_ok(
  $$ update public.items set title = 'hack' $$,
  '42501', null, 'authenticated không UPDATE thẳng items');
select is((select count(*) from public.items), 1::bigint, 'Alice thấy item của mình');
select is((select count(*) from public.profiles), 1::bigint, 'Alice chỉ thấy profile của mình');

select lives_ok($$ update public.profiles set home_tz = 'America/New_York' where id = auth.uid() $$,
  'user sửa được home_tz');
select throws_ok($$ update public.profiles set home_tz = 'Mars/Olympus' where id = auth.uid() $$,
  '23514', null, 'múi giờ không hợp lệ bị từ chối');
select throws_ok($$ update public.profiles set inbound_email_token = 'x' where id = auth.uid() $$,
  '42501', null, 'không sửa được inbound_email_token');

reset role;
select pg_temp.claims(pg_temp.u('bob'));
set local role authenticated;
select is((select count(*) from public.items), 0::bigint, 'Bob không thấy item của Alice');
reset role;

select * from finish();
rollback;
