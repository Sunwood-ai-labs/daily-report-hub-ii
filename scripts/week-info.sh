#!/usr/bin/env bash
set -euo pipefail

# Calculate weekly info. Usage: week-info.sh [WEEK_START_DAY] [DATE]
# - WEEK_START_DAY: 0=Sun, 1=Mon, ... 6=Sat (default 1)
# - DATE: YYYY-MM-DD for the report date (default: today)

WEEK_START_DAY=${1:-1}
DATE=${2:-$(date '+%Y-%m-%d')}

YEAR=$(date -d "$DATE" '+%Y')

# Day of week for DATE (0=Sun)
CURRENT_DAY_OF_WEEK=$(date -d "$DATE" '+%w')
DAYS_SINCE_WEEK_START=$(( (CURRENT_DAY_OF_WEEK - WEEK_START_DAY + 7) % 7 ))
WEEK_START_DATE=$(date -d "$DATE -$DAYS_SINCE_WEEK_START days" '+%Y-%m-%d')
WEEK_END_DATE=$(date -d "$WEEK_START_DATE +6 days" '+%Y-%m-%d')

# Compute week number relative to first week start of the year
YEAR_START="$YEAR-01-01"
YEAR_START_DAY_OF_WEEK=$(date -d "$YEAR_START" '+%w')
FIRST_WEEK_START_OFFSET=$(( (WEEK_START_DAY - YEAR_START_DAY_OF_WEEK + 7) % 7 ))
FIRST_WEEK_START=$(date -d "$YEAR_START +$FIRST_WEEK_START_OFFSET days" '+%Y-%m-%d')

DAYS_DIFF=$(( ( $(date -d "$WEEK_START_DATE" '+%s') - $(date -d "$FIRST_WEEK_START" '+%s') ) / 86400 ))
WEEK_NUMBER=$(( DAYS_DIFF / 7 + 1 ))

WEEK_FOLDER=$(printf "week-%02d_%s_to_%s" "$WEEK_NUMBER" "$WEEK_START_DATE" "$WEEK_END_DATE")

# Export for caller
export DATE YEAR WEEK_START_DATE WEEK_END_DATE WEEK_NUMBER WEEK_FOLDER

echo "DATE=$DATE"
echo "YEAR=$YEAR"
echo "WEEK_NUMBER=$WEEK_NUMBER"
echo "WEEK_START_DATE=$WEEK_START_DATE"
echo "WEEK_END_DATE=$WEEK_END_DATE"
echo "WEEK_FOLDER=$WEEK_FOLDER"

