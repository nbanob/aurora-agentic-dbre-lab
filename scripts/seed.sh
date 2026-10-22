#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
if [[ "${DAT302_CONFIRM_DESTRUCTIVE:-}" != "yes" ]]; then
  echo "This script DROPS AND RECREATES DAT302 tables. It must ONLY run on the dedicated disposable hr_messy lab DB." >&2
  echo "To proceed: export DAT302_CONFIRM_DESTRUCTIVE=yes" >&2
  exit 2
fi
: "${PGHOST:?Source scripts/load_env.sh first}"
: "${PGDATABASE:?Source scripts/load_env.sh first}"
[[ "$PGDATABASE" == "hr_messy" ]] || { echo "Refusing to seed non-lab database $PGDATABASE" >&2; exit 2; }
rows="${DAT302_EMPLOYEE_ROWS:-200000}"
[[ "$rows" =~ ^[0-9]+$ ]] && (( rows >= 1000 && rows <= 6000000 )) || { echo "DAT302_EMPLOYEE_ROWS must be integer 1000..6000000" >&2; exit 2; }
command -v psql >/dev/null || { echo "psql client missing" >&2; exit 1; }
psql -X -v ON_ERROR_STOP=1 -v employee_rows="$rows" --file "$root/scripts/seed.sql"
echo "Seeded employees=$rows. This independently authored 200k-row quick seed is distinct from the original workshop 3M-row dataset."
