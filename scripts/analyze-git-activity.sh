#!/usr/bin/env bash
set -euo pipefail

# Analyze git activity for a given repository directory and date
# Usage: analyze-git-activity.sh <repo_dir> [DATE]

REPO_DIR=${1:?"repo_dir is required"}
DATE=${2:-$(date '+%Y-%m-%d')}
OUT_DIR=${OUT_DIR:-"$PWD/_analysis_out"}
# Make absolute to be safe after pushd
OUT_DIR=$(readlink -f "$OUT_DIR")
mkdir -p "$OUT_DIR"

pushd "$REPO_DIR" >/dev/null

echo "🔍 Analyzing $REPO_DIR for $DATE"

git fetch --all --tags --prune >/dev/null 2>&1 || true

git log --since="$DATE 00:00:00" --until="$DATE 23:59:59" \
  --pretty=format:"%h|%s|%an|%ad" --date=format:'%H:%M:%S' \
  --reverse > "$OUT_DIR/daily_commits_raw.txt" || true

COMMIT_COUNT=$(wc -l < "$OUT_DIR/daily_commits_raw.txt" 2>/dev/null || echo 0)

if [ "${COMMIT_COUNT:-0}" -gt 0 ]; then
  FIRST_COMMIT_TODAY=$(git log --since="$DATE 00:00:00" --pretty=format:"%H" --reverse | head -1)
  LAST_COMMIT_TODAY=$(git log --since="$DATE 00:00:00" --pretty=format:"%H" | head -1)

  if git rev-parse --verify "$FIRST_COMMIT_TODAY^" >/dev/null 2>&1; then
    PARENT_OF_FIRST=$(git rev-parse "$FIRST_COMMIT_TODAY^")
    git diff "$PARENT_OF_FIRST..$LAST_COMMIT_TODAY" --name-status > "$OUT_DIR/daily_cumulative_diff_raw.txt" 2>/dev/null || echo "" > "$OUT_DIR/daily_cumulative_diff_raw.txt"
    git diff "$PARENT_OF_FIRST..$LAST_COMMIT_TODAY" --stat > "$OUT_DIR/daily_diff_stats_raw.txt" 2>/dev/null || echo "" > "$OUT_DIR/daily_diff_stats_raw.txt"
    git diff "$PARENT_OF_FIRST..$LAST_COMMIT_TODAY" > "$OUT_DIR/daily_code_diff_raw.txt" 2>/dev/null || echo "" > "$OUT_DIR/daily_code_diff_raw.txt"
  else
    git diff --name-status 4b825dc642cb6eb9a060e54bf8d69288fbee4904.."$LAST_COMMIT_TODAY" > "$OUT_DIR/daily_cumulative_diff_raw.txt" 2>/dev/null || echo "" > "$OUT_DIR/daily_cumulative_diff_raw.txt"
    git diff --stat 4b825dc642cb6eb9a060e54bf8d69288fbee4904.."$LAST_COMMIT_TODAY" > "$OUT_DIR/daily_diff_stats_raw.txt" 2>/dev/null || echo "" > "$OUT_DIR/daily_diff_stats_raw.txt"
    git show "$LAST_COMMIT_TODAY" > "$OUT_DIR/daily_code_diff_raw.txt" 2>/dev/null || echo "" > "$OUT_DIR/daily_code_diff_raw.txt"
  fi
else
  echo "No commits found for $DATE" > "$OUT_DIR/daily_cumulative_diff_raw.txt"
  echo "No commits found for $DATE" > "$OUT_DIR/daily_diff_stats_raw.txt"
  echo "No commits found for $DATE" > "$OUT_DIR/daily_code_diff_raw.txt"
fi

git diff HEAD~1 --name-status > "$OUT_DIR/latest_diff_raw.txt" 2>/dev/null || echo "" > "$OUT_DIR/latest_diff_raw.txt"
git diff HEAD~1 > "$OUT_DIR/latest_code_diff_raw.txt" 2>/dev/null || echo "" > "$OUT_DIR/latest_code_diff_raw.txt"

popd >/dev/null

echo "OUT_DIR=$OUT_DIR"
