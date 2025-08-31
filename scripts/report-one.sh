#!/usr/bin/env bash
set -euo pipefail

# Orchestrate analysis and report generation for a single repository
# Usage: report-one.sh <repo_clone_url_or_path> [WEEK_START_DAY] [DATE]

REPO_SRC=${1:?"Repository URL or local path is required"}
WEEK_START_DAY=${2:-1}
REPORT_DATE=${3:-$(date '+%Y-%m-%d')}

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

# Compute week info
source scripts/week-info.sh "$WEEK_START_DAY" "$REPORT_DATE" >/dev/null

# Build target structure
TARGET_INFO=$(scripts/create-docusaurus-structure.sh "$REPORT_ROOT" "$YEAR" "$WEEK_FOLDER" "$DATE" "$REPO_NAME" "$WEEK_NUMBER" "$WEEK_START_DATE" "$WEEK_END_DATE")
TARGET_DIR=$(echo "$TARGET_INFO" | sed -n 's/^TARGET_DIR=//p')

# Analyze
OUT_DIR="$RAW_ROOT/$REPO_NAME-$DATE"
OUT_DIR="$OUT_DIR" scripts/analyze-git-activity.sh "$CLONE_DIR" "$DATE" >/dev/null

# Generate markdowns
scripts/generate-markdown-reports.sh "$OUT_DIR" "$TARGET_DIR" "$REPO_NAME" "$DATE" >/dev/null

# README fallback
if [ ! -f "$TARGET_DIR/README.md" ]; then
  echo "# $REPO_NAME" > "$TARGET_DIR/README.md"
fi

# metadata
COMMITS_COUNT=$(wc -l < "$OUT_DIR/daily_commits_raw.txt" 2>/dev/null || echo 0)
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
