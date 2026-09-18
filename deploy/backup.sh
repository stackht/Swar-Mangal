#!/usr/bin/env bash
# Nightly Postgres backup, kept for 14 days. Postgres is the source of truth;
# the Sheets mirror is NOT a backup (it can be rebuilt from here, not the reverse).
#
# crontab -e:
#   15 2 * * * /opt/swarmangal/deploy/backup.sh >> /opt/swarmangal/deploy/backups/backup.log 2>&1
set -euo pipefail
cd "$(dirname "$0")"
set -a; . ./.env; set +a

mkdir -p backups
file="backups/swarmangal-$(date +%Y%m%d-%H%M%S).dump"
docker compose exec -T db pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc > "$file"

# refuse to keep (or rotate on) an empty dump
if [ ! -s "$file" ]; then
  echo "$(date -Is) backup FAILED: empty dump $file" >&2
  rm -f "$file"
  exit 1
fi
find backups -name 'swarmangal-*.dump' -mtime +14 -delete
echo "$(date -Is) backup ok: $file ($(du -h "$file" | cut -f1))"
