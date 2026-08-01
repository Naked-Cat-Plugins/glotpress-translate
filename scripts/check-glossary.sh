#!/usr/bin/env bash
#
# Checks the cached official pt-PT glossary state
# (references/glossario-pt-pt.csv) and prints a single status line for the
# skill to decide whether a refresh is needed:
#
#   MISSING        — the CSV does not exist; update-glossary.sh must be run
#   STALE <days>   — exists but the last update was more than N days ago
#   OK <days>      — exists and is fresh
#
# Adapted from fabiomsnunes/wp-translate-pt-pt (GPLv2) — same check/refresh
# pattern, retargeted at this skill's own references/ folder.
#
# Usage (from the skill folder):
#   scripts/check-glossary.sh          # 30-day threshold
#   scripts/check-glossary.sh 14       # 14-day threshold
#
set -euo pipefail

MAX_DAYS="${1:-30}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV="${SCRIPT_DIR}/../references/glossario-pt-pt.csv"
STAMP="${SCRIPT_DIR}/../references/.glossary-updated"

if [[ ! -f "${CSV}" ]]; then
  echo "MISSING"
  exit 0
fi

# Converts an ISO date (YYYY-MM-DD) to epoch, portable across BSD (macOS) and GNU.
to_epoch() {
  date -j -f "%Y-%m-%d" "$1" +%s 2>/dev/null || date -d "$1" +%s 2>/dev/null
}

last_date=""
if [[ -f "${STAMP}" ]]; then
  last_date="$(head -1 "${STAMP}" | tr -d '[:space:]')"
fi

if [[ -z "${last_date}" ]]; then
  # Without a stamp we can't tell the age — treat as stale to force a refresh.
  echo "STALE ?"
  exit 0
fi

last_epoch="$(to_epoch "${last_date}" || true)"
now_epoch="$(date +%s)"

if [[ -z "${last_epoch}" ]]; then
  echo "STALE ?"
  exit 0
fi

age_days=$(( (now_epoch - last_epoch) / 86400 ))

if (( age_days > MAX_DAYS )); then
  echo "STALE ${age_days}"
else
  echo "OK ${age_days}"
fi
