-- Checklist hành lý trên trips: ghi qua sync_push, LWW cả mảng, chặn giá trị không phải mảng.
begin;
\ir _helpers.psql
select plan(4);

select pg_temp.mk_user(pg_temp.u('alice'));

create temp table r (n int, res jsonb);
grant all on r to authenticated;

insert into r select 1, pg_temp.push(pg_temp.u('alice'), jsonb_build_array(pg_temp.up('trips', pg_temp.u('t1'),
  '{"title":"Hà Nội","packing":[{"id":"a","text":"Hộ chiếu","done":false,"group":"documents"}]}', 1000)));
select is((select packing->0->>'text' from public.trips where id = pg_temp.u('t1')), 'Hộ chiếu', 'packing ghi qua sync_push');

insert into r select 2, pg_temp.push(pg_temp.u('alice'), jsonb_build_array(pg_temp.up('trips', pg_temp.u('t1'),
  '{"packing":[{"id":"a","text":"Hộ chiếu","done":true,"group":"documents"}]}', 2000)));
select is((select (packing->0->>'done')::bool from public.trips where id = pg_temp.u('t1')), true, 'clock mới hơn thay cả mảng');

insert into r select 3, pg_temp.push(pg_temp.u('alice'), jsonb_build_array(pg_temp.up('trips', pg_temp.u('t1'),
  '{"packing":[]}', 1500)));
select is((select jsonb_array_length(packing) from public.trips where id = pg_temp.u('t1')), 1, 'clock cũ hơn bị bỏ qua');

insert into r select 4, pg_temp.push(pg_temp.u('alice'), jsonb_build_array(pg_temp.up('trips', pg_temp.u('t1'),
  '{"packing":{"text":"x"}}', 3000)));
select isnt((select res->0->>'status' from r where n = 4), 'ok', 'packing không phải mảng bị từ chối');

select * from finish();
rollback;
