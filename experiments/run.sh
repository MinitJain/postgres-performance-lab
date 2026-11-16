#!/usr/bin/env bash
# Index experiments for the lesson_progress query.
# Runs each scenario on a freshly seeded table: 3 warm-up runs, then 20 timed runs, reports median.
# Uses a throwaway container so the lab's own volume is untouched.
set -euo pipefail
cd "$(dirname "$0")/.."

C=pglab-exp
OUT=experiments/results
RUNS=20
mkdir -p "$OUT"

docker rm -f $C >/dev/null 2>&1 || true
docker run -d --rm --name $C -e POSTGRES_PASSWORD=x postgres:17 >/dev/null
until docker exec $C pg_isready -U postgres -q 2>/dev/null; do sleep 1; done
sleep 2

psql() { docker exec -i $C psql -U postgres -X -q -v ON_ERROR_STOP=1 "$@"; }

QUERY="SELECT lesson_id, completed_at FROM lesson_progress
WHERE user_id = 142 AND completed_at IS NOT NULL
ORDER BY completed_at DESC"

reset_table() {
  psql -c "DROP TABLE IF EXISTS lesson_progress;" >/dev/null
  psql < sql/01_schema.sql >/dev/null
  psql < sql/02_seed_data.sql >/dev/null
}

# $1 = name, $2 = session settings (e.g. SET enable_bitmapscan = off;)
measure() {
  local name=$1 settings=${2:-}
  psql -c "$settings EXPLAIN (ANALYZE, BUFFERS) $QUERY" > "$OUT/$name.plan.txt"
  local times=()
  for i in $(seq 1 $((RUNS + 3))); do
    t=$(psql -At -c "$settings EXPLAIN (ANALYZE, FORMAT JSON) $QUERY" \
        | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["Execution Time"])')
    [ "$i" -gt 3 ] && times+=("$t")
  done
  printf '%s\n' "${times[@]}" > "$OUT/$name.times.txt"
  median=$(printf '%s\n' "${times[@]}" | python3 -c 'import sys,statistics; print(f"{statistics.median(float(x) for x in sys.stdin):.3f}")')
  node=$(grep -m1 -oE '(Seq Scan|Index Only Scan|Index Scan|Bitmap Heap Scan)' "$OUT/$name.plan.txt")
  sorted=$(grep -q 'Sort Key' "$OUT/$name.plan.txt" && echo yes || echo no)
  heap=$(grep -m1 -oE 'Heap Blocks: exact=[0-9]+|Heap Fetches: [0-9]+' "$OUT/$name.plan.txt" || echo -)
  bufs=$(grep -m1 -oE 'Buffers: shared hit=[0-9]+' "$OUT/$name.plan.txt" || echo -)
  printf '| %s | %s | %s | %s | %s | %s ms |\n' "$name" "$node" "$sorted" "$heap" "$bufs" "$median" | tee -a "$OUT/summary.md"
}

printf '| scenario | scan | sort? | heap | buffers | median exec (n=%s) |\n|---|---|---|---|---|---|\n' $RUNS > "$OUT/summary.md"

# 1. No index (same query as after-index, so the comparison is fair)
reset_table; psql -c "VACUUM ANALYZE lesson_progress;" >/dev/null
measure 1-no-index

# 2. Composite index, planner's choice
psql < sql/04_create_index.sql >/dev/null; psql -c "ANALYZE lesson_progress;" >/dev/null
measure 2-index

# 2b. Tell the planner random reads are cheap (SSD / data in RAM)
measure 2b-index-ssd-cost "SET random_page_cost = 1.1;"

# 3. Same index, bitmap scans disabled -> plain index scan keeps index order
measure 3-index-no-bitmap "SET enable_bitmapscan = off;"

# 3b. Also forbid seq scans -> forces the plain index scan the planner rejected
measure 3b-forced-index-scan "SET enable_bitmapscan = off; SET enable_seqscan = off;"

# 4. Physically reorder the table by the index, then let the planner choose
psql -c "CLUSTER lesson_progress USING idx_lesson_progress_user_completed; ANALYZE lesson_progress;" >/dev/null
measure 4-clustered

# 5. Fresh table, covering index + VACUUM (visibility map) -> index-only scan
reset_table
psql -c "CREATE INDEX idx_cover ON lesson_progress (user_id, completed_at DESC) INCLUDE (lesson_id);" >/dev/null
psql -c "VACUUM ANALYZE lesson_progress;" >/dev/null
measure 5-covering-index

# 6. Same covering index, but no VACUUM after fresh writes (visibility map empty)
reset_table
psql -c "CREATE INDEX idx_cover ON lesson_progress (user_id, completed_at DESC) INCLUDE (lesson_id); ANALYZE lesson_progress;" >/dev/null
measure 6-covering-no-vacuum

psql -At -c "SELECT version();" > "$OUT/env.txt"
uname -mrs >> "$OUT/env.txt"
docker rm -f $C >/dev/null
echo "done -> $OUT/summary.md"
