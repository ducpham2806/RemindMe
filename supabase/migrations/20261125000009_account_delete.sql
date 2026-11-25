-- Xóa tài khoản trong app (security-privacy.md §6, US-52; yêu cầu của Apple và Google).
-- Xóa auth.users ngay: khóa ngoại cascade xóa profile và mọi bảng dữ liệu, phiên đăng nhập, lịch sử thiết bị.
-- Việc ngoài DB (file Storage, thu hồi token tích hợp phía provider) chưa có: worker đọc app.account_deletions rồi xóa hàng khi xong,
-- hạn ≤ 30 ngày. Bảng chỉ giữ uuid + thời điểm, không giữ email hay nội dung.
create table app.account_deletions (
  user_id uuid primary key,
  requested_at timestamptz not null default now()
);
revoke all on app.account_deletions from public, anon, authenticated;

create function public.account_delete() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
begin
  -- Chỉ phiên đang hoạt động mới xóa được (máy đã bị đăng xuất thì không).
  perform app.require_active_session();
  insert into app.account_deletions (user_id) values (v_uid) on conflict (user_id) do nothing;
  delete from auth.users where id = v_uid;
  return jsonb_build_object('deleted', true, 'requested_at', now());
end $$;

revoke all on function public.account_delete() from public, anon;
grant execute on function public.account_delete() to authenticated;
