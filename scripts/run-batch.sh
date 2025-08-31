#!/usr/bin/env bash
set -euo pipefail

# Run reports for all repositories listed in repos.list
# Usage: run-batch.sh [repos_list_path]

REPO_LIST=${1:-repos.list}
WEEK_START_DAY=${WEEK_START_DAY:-1}
REPORT_DATE=${REPORT_DATE:-$(date '+%Y-%m-%d')}

if [ ! -f "$REPO_LIST" ]; then
  echo "Repository list not found: $REPO_LIST" >&2
  exit 1
fi

chmod +x scripts/*.sh || true

while IFS= read -r line; do
  # skip blanks and comments
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  # Expand environment variables if present in the line (e.g., tokens/hosts)
  REPO_URL=$(eval echo "$line")
  echo "=============================="
  echo "Processing: $REPO_URL"
  scripts/report-one.sh "$REPO_URL" "$WEEK_START_DAY" "$REPORT_DATE"
done < "$REPO_LIST"

echo "All repositories processed."
