#!/usr/bin/env bash
set -euo pipefail

# Default to Japan time unless caller overrides TZ
TZ=${TZ:-Asia/Tokyo}
export TZ

# Create Docusaurus-like structure under REPORT_ROOT for given metadata
# Usage: create-docusaurus-structure.sh <REPORT_ROOT> <YEAR> <WEEK_FOLDER> <DATE> <REPO_NAME> <WEEK_NUMBER> <WEEK_START_DATE> <WEEK_END_DATE>

REPORT_ROOT=${1:?"REPORT_ROOT required (e.g., docs/activities)"}
YEAR=${2:?}
WEEK_FOLDER=${3:?}
DATE=${4:?}
REPO_NAME=${5:?}
WEEK_NUMBER=${6:?}
WEEK_START_DATE=${7:?}
WEEK_END_DATE=${8:?}

ACTIVITIES_DIR="$REPORT_ROOT"
YEAR_DIR="$ACTIVITIES_DIR/$YEAR"
WEEK_DIR="$YEAR_DIR/$WEEK_FOLDER"
DATE_DIR="$WEEK_DIR/$DATE"
TARGET_DIR="$DATE_DIR/$REPO_NAME"

mkdir -p "$TARGET_DIR"

if [ ! -f "$ACTIVITIES_DIR/_category_.json" ]; then
  cat > "$ACTIVITIES_DIR/_category_.json" << 'EOF'
{
  "label": "📊 Activities",
  "position": 1,
  "link": { "type": "generated-index", "description": "Daily development activities and reports" }
}
EOF
fi

if [ ! -f "$YEAR_DIR/_category_.json" ]; then
  cat > "$YEAR_DIR/_category_.json" << EOF
{
  "label": "$YEAR",
  "position": 1,
  "link": { "type": "generated-index", "description": "Activities for year $YEAR" }
}
EOF
fi

if [ ! -f "$WEEK_DIR/_category_.json" ]; then
  WEEK_LABEL="Week $WEEK_NUMBER ($WEEK_START_DATE to $WEEK_END_DATE)"
  cat > "$WEEK_DIR/_category_.json" << EOF
{
  "label": "$WEEK_LABEL",
  "position": $WEEK_NUMBER,
  "link": { "type": "generated-index", "description": "Activities for $WEEK_LABEL" }
}
EOF
fi

if [ ! -f "$DATE_DIR/_category_.json" ]; then
  DATE_LABEL="📅 $DATE"
  DATE_POSITION=$(date -d "$DATE" '+%d' | sed 's/^0*//')
  cat > "$DATE_DIR/_category_.json" << EOF
{
  "label": "$DATE_LABEL",
  "position": $DATE_POSITION,
  "link": { "type": "generated-index", "description": "Activities for $DATE" }
}
EOF
fi

if [ ! -f "$TARGET_DIR/_category_.json" ]; then
  cat > "$TARGET_DIR/_category_.json" << EOF
{
  "label": "🔧 $REPO_NAME",
  "position": 1,
  "link": { "type": "generated-index", "description": "Repository: $REPO_NAME" }
}
EOF
fi

echo "TARGET_DIR=$TARGET_DIR"
