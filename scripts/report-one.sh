#!/usr/bin/env bash
set -Euo pipefail

# Default to Japan time unless caller overrides TZ
TZ=${TZ:-Asia/Tokyo}
export TZ

# Error trap to surface failing command and context
on_error() {
  local exit_code=$?
  local line=${BASH_LINENO[0]:-unknown}
  echo "\n💥 report-one.sh failed (exit=${exit_code}) at line ${line}" >&2
  echo "  REPO_SRC=${REPO_SRC:-}" >&2
  echo "  REPO_NAME=${REPO_NAME:-}" >&2
  echo "  DATE=${DATE:-}" >&2
  echo "  CLONE_DIR=${CLONE_DIR:-}" >&2
  echo "  OUT_DIR=${OUT_DIR:-}" >&2
  # Show basic git status if available
  if [ -n "${CLONE_DIR:-}" ] && [ -d "${CLONE_DIR}/.git" ]; then
    echo "--- git status (${REPO_NAME}) ---" >&2
    git -C "$CLONE_DIR" status -sb 2>&1 || true
    echo "--- git last commits (${REPO_NAME}) ---" >&2
    git -C "$CLONE_DIR" log --oneline -n 5 2>&1 || true
    echo "--- git remotes (${REPO_NAME}) ---" >&2
    git -C "$CLONE_DIR" remote -v 2>&1 || true
  fi
  # Show OUT_DIR contents if available
  if [ -n "${OUT_DIR:-}" ] && [ -d "${OUT_DIR}" ]; then
    echo "--- OUT_DIR contents ---" >&2
    ls -la "$OUT_DIR" 2>&1 || true
  fi
}
trap on_error ERR

# Optional trace for debugging
if [[ "${TRACE:-}" == "1" || "${DEBUG:-}" == "1" ]]; then
  set -x
fi

QUIET=1
if [[ "${TRACE:-}" == "1" || "${DEBUG:-}" == "1" ]]; then
  QUIET=0
fi

# Orchestrate analysis and report generation for a single repository
# Usage: report-one.sh <repo_clone_url_or_path> [WEEK_START_DAY] [DATE]

REPO_SRC=${1:?"Repository URL or local path is required"}
WEEK_START_DAY=${2:-1}
REPORT_DATE=${3:-$(date '+%Y-%m-%d')}
# Keep a unified DATE variable used across helper scripts
DATE="$REPORT_DATE"

WORK_ROOT=${WORK_ROOT:-"work"}
RAW_ROOT=${RAW_ROOT:-".tmp/raw"}
REPORT_ROOT=${REPORT_ROOT:-"docs/activities"}

mkdir -p "$WORK_ROOT" "$RAW_ROOT" "$REPORT_ROOT"

# Derive slug
if [[ "$REPO_SRC" =~ \/([^\/]+?)(\.git)?$ ]]; then
  REPO_NAME="${BASH_REMATCH[1]}"
else
  REPO_NAME=$(basename "$REPO_SRC")
fi

# Handle current-dir like './' yielding '.'
if [ "$REPO_SRC" = "." ] || [ "$REPO_SRC" = "./" ] || [ "$REPO_NAME" = "." ]; then
  REPO_NAME=$(basename "$(pwd)")
fi

CLONE_DIR="$WORK_ROOT/$REPO_NAME"

# Clone or update
if [ -d "$CLONE_DIR/.git" ]; then
  echo "↻ Updating $REPO_NAME"
  git -C "$CLONE_DIR" fetch --all --tags --prune
  git -C "$CLONE_DIR" checkout -q $(git -C "$CLONE_DIR" symbolic-ref --short HEAD 2>/dev/null || echo main) || true
  git -C "$CLONE_DIR" pull --ff-only || true
else
  echo "⬇️ Cloning $REPO_SRC -> $CLONE_DIR"
  git clone --no-single-branch "$REPO_SRC" "$CLONE_DIR"
fi

# Analyze first (to decide skip/no-skip)
OUT_DIR="$RAW_ROOT/$REPO_NAME-$DATE"
if [ "$QUIET" -eq 1 ]; then
  OUT_DIR="$OUT_DIR" scripts/analyze-git-activity.sh "$CLONE_DIR" "$DATE" >/dev/null
else
  echo "Running analyze-git-activity.sh (OUT_DIR=$OUT_DIR)" >&2
  OUT_DIR="$OUT_DIR" scripts/analyze-git-activity.sh "$CLONE_DIR" "$DATE"
fi

# If no commits for the day, skip creating any docs
COMMITS_COUNT=$(wc -l < "$OUT_DIR/daily_commits_raw.txt" 2>/dev/null || echo 0)
if [ "${COMMITS_COUNT:-0}" -eq 0 ]; then
  echo "ℹ️  No commits for $DATE in $REPO_NAME — skipping report."
  exit 0
fi

# Compute week info (only when generating)
if [ "$QUIET" -eq 1 ]; then
  source scripts/week-info.sh "$WEEK_START_DAY" "$REPORT_DATE" >/dev/null
else
  echo "Sourcing week-info.sh (WEEK_START_DAY=$WEEK_START_DAY, DATE=$REPORT_DATE)" >&2
  source scripts/week-info.sh "$WEEK_START_DAY" "$REPORT_DATE"
fi

# Build target structure
if [ "$QUIET" -eq 1 ]; then
  TARGET_INFO=$(scripts/create-docusaurus-structure.sh "$REPORT_ROOT" "$YEAR" "$WEEK_FOLDER" "$DATE" "$REPO_NAME" "$WEEK_NUMBER" "$WEEK_START_DATE" "$WEEK_END_DATE")
else
  echo "Creating Docusaurus structure..." >&2
  TARGET_INFO=$(scripts/create-docusaurus-structure.sh "$REPORT_ROOT" "$YEAR" "$WEEK_FOLDER" "$DATE" "$REPO_NAME" "$WEEK_NUMBER" "$WEEK_START_DATE" "$WEEK_END_DATE")
  echo "TARGET_INFO=$TARGET_INFO" >&2
fi
TARGET_DIR=$(echo "$TARGET_INFO" | sed -n 's/^TARGET_DIR=//p')

# Generate markdowns
if [ "$QUIET" -eq 1 ]; then
  scripts/generate-markdown-reports.sh "$OUT_DIR" "$TARGET_DIR" "$REPO_NAME" "$DATE" >/dev/null
else
  echo "Generating markdown reports into $TARGET_DIR" >&2
  scripts/generate-markdown-reports.sh "$OUT_DIR" "$TARGET_DIR" "$REPO_NAME" "$DATE"
fi

# README fallback
if [ ! -f "$TARGET_DIR/README.md" ]; then
  echo "# $REPO_NAME" > "$TARGET_DIR/README.md"
fi

# metadata
FILES_CHANGED=$(grep -c '^' "$OUT_DIR/daily_cumulative_diff_raw.txt" 2>/dev/null || echo 0)
cat > "$TARGET_DIR/metadata.json" << EOF
{
  "repository": "$REPO_SRC",
  "date": "$DATE",
  "week_folder": "$WEEK_FOLDER",
  "week_number": $WEEK_NUMBER,
  "week_start_date": "$WEEK_START_DATE",
  "week_end_date": "$WEEK_END_DATE",
  "daily_commit_count": $COMMITS_COUNT,
  "daily_files_changed": $FILES_CHANGED
}
EOF

echo "✅ Report generated for $REPO_NAME -> $TARGET_DIR"
