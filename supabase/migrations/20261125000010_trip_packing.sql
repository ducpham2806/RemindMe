-- Checklist hành lý của chuyến (UX §2.5, Figma 23): mảng [{id, text, done, group}] trên trips, đồng bộ như mọi trường
-- (LWW cả mảng theo field_clock). group: 'documents'|'devices'|'personal'|'clothes'|'other' (app dịch tên nhóm theo ngôn ngữ).
-- sync_push đọc cột qua app.writable_cols nên không cần sửa RPC; client cũ không gửi cột này.
alter table public.trips add column packing jsonb;
alter table public.trips add constraint trips_packing_array
  check (packing is null or (jsonb_typeof(packing) = 'array' and jsonb_array_length(packing) <= 200));
