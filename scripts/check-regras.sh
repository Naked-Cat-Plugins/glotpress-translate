#!/usr/bin/env bash
#
# Checks the cached pt-PT rules state (references/regras-pt.md) and prints a
# single status line so the skill can decide whether a refresh is needed:
#
#   MISSING        — the file does not exist; needs (re-)fetching from the guide
#   STALE <days>   — exists but the last refresh was more than N days ago
#   OK <days>      — exists and is fresh
#
# Unlike the glossary, there is no deterministic download for this file — a
# refresh means WebFetching the live guide page
# (https://pt.wordpress.org/traducoes/guia-de-tradutores-portugues-de-portugal-pt_pt/)
# and rewriting regras-pt.md's content by hand (see SKILL.md's glossary/rules
# sync step). This script only reports freshness, same threshold convention as
# check-glossary.sh.
#
# Usage (from the skill folder):
#   scripts/check-regras.sh          # 30-day threshold
#   scripts/check-regras.sh 14       # 14-day threshold
#
set -euo pipefail

MAX_DAYS="${1:-30}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE="${SCRIPT_DIR}/../references/regras-pt.md"
STAMP="${SCRIPT_DIR}/../references/.regras-updated"

if [[ ! -f "${FILE}" ]]; then
  echo "MISSING"
  exit 0
fi

to_epoch() {
  date -j -f "%Y-%m-%d" "$1" +%s 2>/dev/null || date -d "$1" +%s 2>/dev/null
}

last_date=""
if [[ -f "${STAMP}" ]]; then
  last_date="$(head -1 "${STAMP}" | tr -d '[:space:]')"
fi

if [[ -z "${last_date}" ]]; then
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
