#!/usr/bin/env bash
# Nightly Postgres backup for aaPanel — no Docker, uses local psql/pg_dump.
#
# crontab -e:
#   15 2 * * * /opt/swarmangal/deploy/aapanel/backup.sh >> /var/log/swarmangal/backup.log 2>&1
set -euo pipefail
cd "$(dirname "$0")/../.."

# Load environment from .env next to this script's parent
if [ -f .env ]; then
  set -a; . ./.env; set +a
fi

BACKUP_DIR="/opt/swarmangal/backups"
mkdir -p "$BACKUP_DIR"

DB_NAME="${POSTGRES_DB:-swarmangal}"
DB_USER="${POSTGRES_USER:-swarmangal}"
DB_HOST="${POSTGRES_HOST:-127.0.0.1}"
DB_PORT="${POSTGRES_PORT:-5432}"

file="$BACKUP_DIR/swarmangal-$(date +%Y%m%d-%H%M%S).dump"
pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -Fc -f "$file"

# Refuse to keep empty dumps
if [ ! -s "$file" ]; then
  echo "$(date -Is) backup FAILED: empty dump $file" >&2
  rm -f "$file"
  exit 1
fi

# Rotate: keep 14 days
find "$BACKUP_DIR" -name 'swarmangal-*.dump' -mtime +14 -delete
echo "$(date -Is) backup ok: $file ($(du -h "$file" | cut -f1))"
