-- Một tài khoản, một thiết bị hoạt động (ADR-013): đá phiên cũ, lịch sử đăng nhập, không giành lại phiên đã bị đá.
begin;
\ir _helpers.psql
select plan(21);

select pg_temp.mk_user(pg_temp.u('alice'));   -- đăng nhập thiết bị 1 (device-1)
select pg_temp.push(pg_temp.u('alice'), jsonb_build_array(pg_temp.up('items', pg_temp.u('i1'), '{"kind":"task","title":"Buy milk"}')));

create temp table r (n int, res jsonb);
grant all on r to authenticated;

-- Thiết bị 2 vừa đăng nhập, chưa claim: thấy thiết bị đang hoạt động để hỏi xác nhận; chưa đọc/ghi được.
insert into auth.sessions (id, user_id) values (pg_temp.sid(pg_temp.u('alice'), 2), pg_temp.u('alice'));
select pg_temp.claims(pg_temp.u('alice'), pg_temp.sid(pg_temp.u('alice'), 2));
set local role authenticated;
insert into r select 1, public.session_status();
select throws_ok($$ select public.sync_pull(0, 10) $$, 'PT403', 'session_not_claimed', 'phiên chưa claim không sync được');
select is((select count(*) from public.items), 0::bigint, 'phiên chưa claim không đọc được bảng (RLS)');
reset role;
select is((select res->>'state' from r where n = 1), 'unclaimed', 'session_status: unclaimed');
select is((select res->'will_replace'->0->>'device_id' from r where n = 1), 'device-1', 'session_status cho biết thiết bị sẽ bị đăng xuất');

-- Claim trên thiết bị 2: thiết bị 1 bị đá.
insert into r select 2, pg_temp.login(pg_temp.u('alice'), 2);
select is((select res->'replaced'->0->>'device_id' from r where n = 2), 'device-1', 'claim trả thiết bị bị đăng xuất');
select is((select status || '/' || end_reason from public.user_sessions where id = pg_temp.sid(pg_temp.u('alice'), 1)),
  'ended/replaced', 'phiên cũ kết thúc với lý do replaced');
select ok((select revoke_notified_at is null from public.user_sessions where id = pg_temp.sid(pg_temp.u('alice'), 1)),
  'phiên bị thay chờ worker push session.revoked');
select ok(not exists (select 1 from auth.sessions where id = pg_temp.sid(pg_temp.u('alice'), 1)),
  'phiên GoTrue cũ bị xóa (refresh token chết)');
select is((select count(*) from public.user_sessions where user_id = pg_temp.u('alice') and status = 'active'), 1::bigint,
  'chỉ còn 1 phiên hoạt động');

-- JWT cũ của thiết bị 1 (chưa hết hạn) không dùng được nữa.
select throws_ok($$ select pg_temp.push(pg_temp.u('alice'), '[]'::jsonb, 'd', pg_temp.sid(pg_temp.u('alice'), 1)) $$,
  'PT403', 'session_revoked', 'thiết bị bị đá: sync_push trả session_revoked');
select pg_temp.claims(pg_temp.u('alice'), pg_temp.sid(pg_temp.u('alice'), 1));
set local role authenticated;
select is((select count(*) from public.items), 0::bigint, 'thiết bị bị đá không đọc được dữ liệu qua PostgREST');
insert into r select 3, public.session_status();
select throws_ok($$ select public.session_claim('device-1', '{}') $$, 'PT403', 'session_revoked',
  'phiên đã bị đá không tự claim lại được');
select throws_ok($$ select public.profile_init('en-US', 'US', 'UTC') $$, 'PT403', 'session_revoked',
  'phiên đã bị đá không đọc profile qua profile_init');
reset role;
select is((select res->'replaced_by'->>'device_model' from r where n = 3), 'iPhone 15',
  'thiết bị bị đá biết đã bị thay bởi máy nào');

-- Thiết bị 2 dùng bình thường.
select is((pg_temp.pull(pg_temp.u('alice'), 0, 100, pg_temp.sid(pg_temp.u('alice'), 2))->'rows'->'items'->0->>'title'), 'Buy milk',
  'thiết bị mới kéo được dữ liệu');

-- Đăng nhập lại trên thiết bị 1 (phiên mới, cùng device-1): thiết bị 2 bị đá; đăng nhập lại cùng máy thì không báo.
select pg_temp.login(pg_temp.u('alice'), 3, 'device-1');
select is((select end_reason from public.user_sessions where id = pg_temp.sid(pg_temp.u('alice'), 2)), 'replaced', 'thiết bị 2 bị đá');
select pg_temp.login(pg_temp.u('alice'), 4, 'device-1');
select is((select end_reason || ':' || (revoke_notified_at is not null) from public.user_sessions where id = pg_temp.sid(pg_temp.u('alice'), 3)),
  'same_device_relogin:true', 'đăng nhập lại cùng máy: kết thúc phiên cũ, không push');

-- Lịch sử đăng nhập: thiết bị đang hoạt động đọc được toàn bộ.
select pg_temp.claims(pg_temp.u('alice'), pg_temp.sid(pg_temp.u('alice'), 4));
set local role authenticated;
select is((select count(*) from public.user_sessions), 4::bigint, 'lịch sử đăng nhập có đủ 4 phiên');
select ok((select public.session_end() ->> 'ended')::bool, 'đăng xuất phiên hiện tại');
reset role;
select is((select end_reason from public.user_sessions where id = pg_temp.sid(pg_temp.u('alice'), 4)), 'signed_out', 'lý do signed_out');

-- Giới hạn số thiết bị lấy từ plan_entitlements (đổi được, không hard-code).
update public.plan_entitlements set value = 2 where plan_id = 'free' and key = 'max_active_devices';
select pg_temp.mk_user(pg_temp.u('bob'));
select pg_temp.login(pg_temp.u('bob'), 2, 'tablet', 'ios', 'tablet');
select is((select count(*) from public.user_sessions where user_id = pg_temp.u('bob') and status = 'active'), 2::bigint,
  'max_active_devices = 2 thì giữ 2 phiên');

select * from finish();
rollback;
