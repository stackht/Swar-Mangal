#!/usr/bin/env bash
# One-time copy of the Railway Postgres into the VPS Postgres.
#
#   RAILWAY_DATABASE_URL='postgresql://...' ./migrate-from-railway.sh
#
# Use Railway's PUBLIC connection string (DATABASE_PUBLIC_URL). Run it BEFORE
# the app has taken any real writes on the VPS: it replaces the VPS database.
# Railway itself is only read from and stays untouched as a fallback.
set -euo pipefail
cd "$(dirname "$0")"
: "${RAILWAY_DATABASE_URL:?set RAILWAY_DATABASE_URL to the Railway public Postgres URL}"
set -a; . ./.env; set +a

mkdir -p backups
dump="backups/railway-$(date +%Y%m%d-%H%M%S).dump"

echo "1/4 dumping Railway (read-only) -> $dump"
docker run --rm -e PGSSLMODE=require postgres:17 \
  pg_dump "$RAILWAY_DATABASE_URL" -Fc --no-owner --no-privileges > "$dump"
[ -s "$dump" ] || { echo "dump is empty, stopping"; exit 1; }

echo "2/4 stopping app and worker so nothing writes during the restore"
docker compose stop app sheets-worker
docker compose up -d db

echo "3/4 restoring into the VPS database"
docker compose exec -T db psql -U "$POSTGRES_USER" -d postgres -c "drop database if exists \"$POSTGRES_DB\" with (force);"
docker compose exec -T db psql -U "$POSTGRES_USER" -d postgres -c "create database \"$POSTGRES_DB\";"
docker compose exec -T db pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" --no-owner --no-privileges < "$dump"

echo "4/4 starting the app (applies schema + migrations), then queueing the full mirror"
docker compose up -d app
sleep 15
docker compose run --rm sheets-worker node sync/worker.mjs --backfill
docker compose up -d sheets-worker
echo "done. Watch it with: docker compose logs -f sheets-worker"
