#!/usr/bin/env bash
set -euo pipefail

# Default to Japan time unless caller overrides TZ
TZ=${TZ:-Asia/Tokyo}
export TZ

# Backfill daily reports for the past N weeks (inclusive of today)
# Usage: run-backfill-weeks.sh <weeks> [repos_list_path]
# Env: WEEK_START_DAY (default 1)

WEEKS=${1:?
"Number of weeks is required (e.g., 4)"}
REPO_LIST=${2:-repos.list}
WEEK_START_DAY=${WEEK_START_DAY:-1}

if ! [[ "$WEEKS" =~ ^[0-9]+$ ]]; then
  echo "WEEKS must be a non-negative integer" >&2
  exit 1
fi

if [ "$WEEKS" -eq 0 ]; then
  echo "Nothing to do: weeks=0" >&2
  exit 0
fi

chmod +x scripts/*.sh || true

DAYS=$(( WEEKS * 7 ))

echo "Starting backfill for the past $WEEKS week(s) ($DAYS days)."

# Iterate from today (0) back to DAYS-1
for offset in $(seq 0 $((DAYS-1))); do
  REPORT_DATE=$(date -d "-$offset days" '+%Y-%m-%d')
  echo "=============================="
  echo "Backfill date: $REPORT_DATE"
  WEEK_START_DAY=$WEEK_START_DAY REPORT_DATE=$REPORT_DATE ./scripts/run-batch.sh "$REPO_LIST" || true
done

echo "Backfill complete."
