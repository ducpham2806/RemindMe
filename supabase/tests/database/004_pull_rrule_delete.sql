-- sync_pull, app.rrule_fires_on, ghi từ worker, xóa tài khoản.
begin;
\ir _helpers.psql
select plan(14);

select pg_temp.mk_user(pg_temp.u('alice'));
select pg_temp.mk_user(pg_temp.u('bob'));
select pg_temp.push(pg_temp.u('alice'), (select jsonb_agg(pg_temp.up('items', pg_temp.u('a' || g), jsonb_build_object('kind', 'task', 'title', 'a' || g))) from generate_series(1, 5) g));
select pg_temp.push(pg_temp.u('bob'), jsonb_build_array(pg_temp.up('items', pg_temp.u('b1'), '{"kind":"task","title":"b1"}')));
select pg_temp.push(pg_temp.u('alice'), jsonb_build_array(pg_temp.del('items', pg_temp.u('a5'))));

create temp table p (n int, res jsonb);
grant all on p to authenticated;

-- Alice có 6 hàng: Inbox + 5 item (a5 là tombstone). Trang 4 rồi trang tiếp.
insert into p select 1, pg_temp.pull(pg_temp.u('alice'), 0, 4);
select is((select (select count(*) from jsonb_each(res->'rows') e, jsonb_array_elements(e.value)) from p where n = 1), 4::bigint, 'trang đầu 4 hàng');
select ok((select (res->>'has_more')::bool from p where n = 1), 'has_more = true');
insert into p select 2, pg_temp.pull(pg_temp.u('alice'), (select (res->>'next_since')::bigint from p where n = 1), 4);
select is((select (select count(*) from jsonb_each(res->'rows') e, jsonb_array_elements(e.value)) from p where n = 2), 2::bigint, 'trang sau 2 hàng còn lại');
select ok((select not (res->>'has_more')::bool from p where n = 2), 'hết dữ liệu: has_more = false');
select ok((select exists (select 1 from jsonb_array_elements(res->'rows'->'items') x where x->>'title' = 'a5' and x->>'deleted_at' is not null) from p where n = 2),
  'tombstone có trong sync_pull');
select ok(not exists (select 1 from p, jsonb_each(res->'rows') e, jsonb_array_elements(e.value) x where x->>'user_id' <> pg_temp.u('alice')::text),
  'không lẫn dữ liệu user khác');

-- RRULE phía server (xấp xỉ chống lách).
select is(app.rrule_fires_on('FREQ=WEEKLY;BYDAY=MO,WE', '2026-11-02', '2026-11-25'), 1, 'WEEKLY BYDAY: thứ Tư kêu');
select is(app.rrule_fires_on('FREQ=WEEKLY;BYDAY=MO,WE', '2026-11-02', '2026-11-26'), 0, 'WEEKLY BYDAY: thứ Năm không kêu');
select is(app.rrule_fires_on('FREQ=WEEKLY;INTERVAL=2;BYDAY=MO', '2026-11-02', '2026-11-09'), 0, 'INTERVAL=2 bỏ tuần lẻ');
select is(app.rrule_fires_on('FREQ=MONTHLY;BYMONTHDAY=-1', '2026-01-31', '2026-02-28'), 1, 'BYMONTHDAY=-1 là ngày cuối tháng');
select is(app.rrule_fires_on('FREQ=DAILY;BYHOUR=8,20;BYMINUTE=0,30', '2026-11-01', '2026-11-24'), 4, 'BYHOUR x BYMINUTE');

-- Worker (service_role) ghi được và version vẫn tăng.
set local role service_role;
update public.items set title = 'from gcal' where id = pg_temp.u('a1');
reset role;
select ok((select version from public.items where id = pg_temp.u('a1')) > (select max(version) from public.items where id <> pg_temp.u('a1') and user_id = pg_temp.u('alice')),
  'ghi từ service_role có version mới nhất');

-- Xóa tài khoản: xóa sạch dữ liệu.
delete from auth.users where id = pg_temp.u('alice');
select is((select count(*) from public.items where user_id = pg_temp.u('alice')), 0::bigint, 'xóa tài khoản xóa items');
select is((select count(*) from public.lists where user_id = pg_temp.u('alice')), 0::bigint, 'xóa tài khoản xóa lists');

select * from finish();
rollback;
