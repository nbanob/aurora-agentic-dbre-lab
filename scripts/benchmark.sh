#!/usr/bin/env bash
set -euo pipefail
: "${PGHOST:?Source scripts/load_env.sh first}"
command -v pgbench >/dev/null || { echo "pgbench missing (install compatible PostgreSQL client packages)" >&2; exit 1; }
root="$(cd "$(dirname "$0")/.." && pwd)"
clients="${DAT302_BENCH_CLIENTS:-4}"
seconds="${DAT302_BENCH_SECONDS:-180}"
# Must match DAT302_EMPLOYEE_ROWS in seed.sh unless manually edited.
rows="${DAT302_EMPLOYEE_ROWS:-200000}"
for n in "$clients" "$seconds" "$rows"; do [[ "$n" =~ ^[0-9]+$ ]] || { echo "Inputs must be integers"; exit 2; }; done
[[ "$seconds" -le 900 ]] || { echo "Benchmark capped at 900 seconds. Edit only after reviewing AWS spend."; exit 2; }
# pgbench script uses a hard-coded dataset upper bound; generate per-run temp script.
work="$(mktemp)"
trap 'rm -f "$work"' EXIT
sed "s/random(1, 200000)/random(1, $rows)/" "$root/scripts/benchmark.sql" > "$work"
echo "Running demo read workload: ${clients} clients for ${seconds}s. Ctrl-C to stop."
pgbench -n -f "$work" -T "$seconds" -c "$clients" -j 2 "$PGDATABASE"
