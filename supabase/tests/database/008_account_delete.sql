-- Xóa tài khoản: cascade sạch dữ liệu của chính mình, không đụng người khác; phiên đã kết thúc hay anon không gọi được.
begin;
\ir _helpers.psql
select plan(7);

select pg_temp.mk_user(pg_temp.u('a'));
select pg_temp.mk_user(pg_temp.u('b'));
insert into public.items (id, user_id, title, kind, device_id) values
  (gen_random_uuid(), pg_temp.u('a'), 'A', 'task', 'device-1'),
  (gen_random_uuid(), pg_temp.u('b'), 'B', 'task', 'device-1');

set local role anon;
select throws_ok($$ select public.account_delete() $$, '42501', null, 'anon không gọi được');
reset role;

-- B: phiên đã bị máy khác thay thì không xóa được.
select pg_temp.login(pg_temp.u('b'), 2, 'b-tablet', 'ios', 'tablet');
select pg_temp.claims(pg_temp.u('b'), pg_temp.sid(pg_temp.u('b'), 1));
set local role authenticated;
select throws_ok($$ select public.account_delete() $$, 'PT403', null, 'phiên đã kết thúc không xóa được');
reset role;

select pg_temp.claims(pg_temp.u('a'));
set local role authenticated;
select is((public.account_delete())->>'deleted', 'true', 'A xóa tài khoản của mình');
reset role;

select is((select count(*) from auth.users where id = pg_temp.u('a')), 0::bigint, 'auth.users của A đã xóa');
select is((select count(*) from public.items where user_id = pg_temp.u('a'))
        + (select count(*) from public.profiles where id = pg_temp.u('a'))
        + (select count(*) from public.user_sessions where user_id = pg_temp.u('a')), 0::bigint, 'cascade: item, profile, phiên của A');
select is((select count(*) from public.items where user_id = pg_temp.u('b')), 1::bigint, 'dữ liệu của B còn nguyên');
select is((select count(*) from app.account_deletions where user_id = pg_temp.u('a')), 1::bigint, 'ghi việc dọn ngoài DB cho worker');

select * from finish();
rollback;
