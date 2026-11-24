-- Plus: đồng thời điện thoại + tablet + máy tính, mỗi loại 1; hạ gói thì cắt về giới hạn Free (ADR-013 sửa đổi 1).
begin;
\ir _helpers.psql
select plan(14);

select pg_temp.mk_user(pg_temp.u('free'));                                -- điện thoại (phiên 1)
select pg_temp.mk_user(pg_temp.u('plus'));
insert into public.subscriptions (user_id, plan_id, status, current_period_end)
  values (pg_temp.u('plus'), 'plus', 'active', now() + interval '30 days');

create function pg_temp.active(p_uid uuid) returns text language sql as $$
  select string_agg(device_class, ',' order by device_class) from public.user_sessions where user_id = p_uid and status = 'active' $$;

-- Free: tablet đăng nhập thì điện thoại bị đá (tổng 1).
select pg_temp.login(pg_temp.u('free'), 2, 'ipad', 'ios', 'tablet');
select is(pg_temp.active(pg_temp.u('free')), 'tablet', 'Free: chỉ 1 thiết bị, máy mới thắng');

-- Plus: điện thoại + tablet + máy tính cùng hoạt động.
select pg_temp.login(pg_temp.u('plus'), 2, 'ipad', 'ios', 'tablet');
select pg_temp.login(pg_temp.u('plus'), 3, 'laptop', 'web', 'phone');   -- web luôn là computer dù app báo gì
select is(pg_temp.active(pg_temp.u('plus')), 'computer,phone,tablet', 'Plus: 3 loại thiết bị cùng lúc');
select is((select device_class from public.user_sessions where id = pg_temp.sid(pg_temp.u('plus'), 3)), 'computer',
  'platform web bị ép thành computer');

-- Xem trước trên điện thoại thứ 2 (chưa claim): chỉ điện thoại cũ sẽ bị đăng xuất.
insert into auth.sessions (id, user_id) values (pg_temp.sid(pg_temp.u('plus'), 4), pg_temp.u('plus'));
select pg_temp.claims(pg_temp.u('plus'), pg_temp.sid(pg_temp.u('plus'), 4));
set local role authenticated;
create temp table r (n int, res jsonb);
insert into r select 1, public.session_status('phone-2', 'android', 'phone');
reset role;
select is((select jsonb_array_length(res->'will_replace') || ':' || (res->'will_replace'->0->>'device_class') from r where n = 1), '1:phone',
  'xem trước: chỉ điện thoại cũ bị đăng xuất');
select is((select (res->>'max_active_devices') || '/' || (res->>'max_devices_per_class') from r where n = 1), '3/1', 'giới hạn Plus 3 tổng, 1 mỗi loại');

-- Điện thoại thứ 2 claim: điện thoại 1 bị đá, tablet và laptop giữ nguyên.
select pg_temp.login(pg_temp.u('plus'), 4, 'phone-2', 'android', 'phone');
select is((select end_reason from public.user_sessions where id = pg_temp.sid(pg_temp.u('plus'), 1)), 'replaced', 'điện thoại cũ bị đá');
select is(pg_temp.active(pg_temp.u('plus')), 'computer,phone,tablet', 'tablet và máy tính vẫn hoạt động');
select is((select count(*) from public.user_sessions where user_id = pg_temp.u('plus') and status = 'active' and device_id = 'phone-2'), 1::bigint,
  'điện thoại mới hoạt động');

-- Hạ gói (webhook ghi expired): cắt về 1 thiết bị, giữ máy hoạt động gần nhất, cần push báo.
update public.user_sessions set last_seen_at = now() - interval '1 hour' where user_id = pg_temp.u('plus') and device_id <> 'laptop';
update public.user_sessions set last_seen_at = now() where user_id = pg_temp.u('plus') and device_id = 'laptop';
update public.subscriptions set status = 'expired' where user_id = pg_temp.u('plus');
select is(pg_temp.active(pg_temp.u('plus')), 'computer', 'hạ gói: giữ thiết bị hoạt động gần nhất');
select is((select count(*) from public.user_sessions where user_id = pg_temp.u('plus') and end_reason = 'plan_limit' and revoke_notified_at is null),
  2::bigint, 'thiết bị bị cắt do hạ gói chờ push session.revoked');
select throws_ok($$ select pg_temp.push(pg_temp.u('plus'), '[]'::jsonb, 'd', pg_temp.sid(pg_temp.u('plus'), 2)) $$,
  'PT403', 'session_revoked', 'tablet bị cắt không sync được');

-- Mua lại Plus không tự mở lại phiên đã kết thúc.
update public.subscriptions set status = 'active' where user_id = pg_temp.u('plus');
select is(pg_temp.active(pg_temp.u('plus')), 'computer', 'mua lại Plus không hồi sinh phiên cũ');

-- Cấu hình: bỏ giới hạn theo loại thì Plus dùng được 2 điện thoại.
update public.plan_entitlements set value = -1 where plan_id = 'plus' and key = 'max_devices_per_class';
select pg_temp.login(pg_temp.u('plus'), 5, 'phone-a', 'ios', 'phone');
select pg_temp.login(pg_temp.u('plus'), 6, 'phone-b', 'android', 'phone');
select is(pg_temp.active(pg_temp.u('plus')), 'computer,phone,phone', 'max_devices_per_class = -1: 2 điện thoại');
select ok(app.device_class_of('ipados', 'phone') = 'tablet', 'ipados luôn là tablet');

select * from finish();
rollback;
