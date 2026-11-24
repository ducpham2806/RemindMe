#!/usr/bin/env bash
# Dựng DB test sạch trên Postgres thuần (không cần Docker/Supabase CLI), áp shim + migrations, chạy pgTAP.
# Cần: psql, pg_prove, extension pgtap (apt: postgresql-16-pgtap). Kết nối qua biến PG* chuẩn
# (PGHOST, PGPORT, PGUSER là superuser). Ví dụ: PGHOST=localhost PGUSER=postgres tools/db-test.sh
# Có Supabase CLI + Docker thì dùng `supabase test db` thay cho script này (không cần shim).
set -euo pipefail
cd "$(dirname "$0")/.."

DB="${DB_TEST_NAME:-remindme_test}"
export PGUSER="${PGUSER:-postgres}"

psql -q -v ON_ERROR_STOP=1 -d postgres -c "drop database if exists $DB" -c "create database $DB" >/dev/null
run() { psql -q -v ON_ERROR_STOP=1 -d "$DB" -f "$1" >/dev/null; }

run supabase/tests/shim/supabase_shim.sql
for f in supabase/migrations/*.sql; do
  echo "migrate: $f"
  run "$f"
done
psql -q -v ON_ERROR_STOP=1 -d "$DB" -c "create extension if not exists pgtap" >/dev/null

pg_prove -d "$DB" --ext .sql -r supabase/tests/database "$@"
