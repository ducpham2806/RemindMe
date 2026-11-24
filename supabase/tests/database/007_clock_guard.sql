-- Clock HLC sai định dạng bị từ chối; clock ở tương lai xa bị kẹp về giờ server.
begin;
\ir _helpers.psql
select plan(7);

select pg_temp.mk_user(pg_temp.u('carol'));
create temp table r (n int, res jsonb);

-- Clock rác thắng mọi clock số nếu không chặn.
insert into r select 1, pg_temp.push(pg_temp.u('carol'), jsonb_build_array(jsonb_build_object(
  'table', 'items', 'id', pg_temp.u('i1'), 'op', 'upsert',
  'payload', '{"kind":"task","title":"x"}'::jsonb, 'field_clock', '{"kind":"zzz","title":"zzz"}'::jsonb)));
select is((select res->0->>'status' from r where n = 1), 'invalid', 'clock sai định dạng: invalid');
select is((select res->0->>'error' from r where n = 1), 'malformed_clock', 'mã lỗi malformed_clock');
select is((select count(*) from public.items where id = pg_temp.u('i1')), 0::bigint, 'không ghi hàng nào');

-- Máy đặt sai sang năm 2030 (≈ 1.9e12 ms): bị kẹp về giờ server.
insert into r select 2, pg_temp.push(pg_temp.u('carol'), jsonb_build_array(
  pg_temp.up('items', pg_temp.u('i2'), '{"kind":"task","title":"from 2030"}', 1900000000000, 'skewed')));
select is((select res->0->>'status' from r where n = 2), 'ok', 'clock tương lai vẫn ghi được');
select ok((select res->0->'clamped' ? 'title' from r where n = 2), 'kết quả báo trường bị kẹp');
select ok((select left(field_clock->>'title', 13)::bigint <= (extract(epoch from now()) * 1000)::bigint + 1000
             and field_clock->>'title' like '%:0000:skewed' from public.items where id = pg_temp.u('i2')),
  'clock lưu = giờ server, giữ counter + node');

-- Máy giờ đúng sửa sau đó (clock = now + 1 phút) thắng bản từ máy sai giờ.
select pg_temp.push(pg_temp.u('carol'), jsonb_build_array(
  pg_temp.up('items', pg_temp.u('i2'), '{"title":"fixed"}', (extract(epoch from now() + interval '1 minute') * 1000)::bigint, 'good')));
select is((select title from public.items where id = pg_temp.u('i2')), 'fixed', 'máy giờ đúng thắng sau khi kẹp');

select * from finish();
rollback;
