#!/usr/bin/env bash
#
# Refreshes the cached official pt-PT glossary (references/glossario-pt-pt.csv)
# from translate.wordpress.org. This is a snapshot of the WordPress Portuguese
# Community's own consolidated glossary — run this when check-glossary.sh
# reports MISSING/STALE, to keep it aligned with the Community's terms.
#
# This is the *official* pt-PT glossary, separate from and in addition to our
# own GlotPress instance's project/global pt glossary (accessed via the
# nakedcat-glotpress/get-glossary and add-glossary-entries abilities). See
# SKILL.md's glossary-sync step for how the two are diffed and merged
# (additive only — never overwrites an existing entry in our own glossary).
#
# Adapted from fabiomsnunes/wp-translate-pt-pt (GPLv2) — same download
# mechanism, retargeted at this skill's own references/ folder.
#
# With no arguments it uses the official pt-PT glossary CSV export endpoint.
# To force a different URL (e.g. if the endpoint changes), pass it as an
# argument or via an environment variable:
#
#     ./update-glossary.sh "<csv-export-link>"
#     GLOSSARY_CSV_URL="<csv-export-link>" ./update-glossary.sh
#
# pt-PT glossary page:
#   https://translate.wordpress.org/locale/pt/default/glossary/
#
set -euo pipefail

DEFAULT_URL="https://translate.wordpress.org/locale/pt/default/glossary/-export/"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/../references/glossario-pt-pt.csv"
STAMP="${SCRIPT_DIR}/../references/.glossary-updated"

URL="${1:-${GLOSSARY_CSV_URL:-${DEFAULT_URL}}}"

TMP="$(mktemp)"
trap 'rm -f "${TMP}"' EXIT

echo "Downloading glossary from: ${URL}"
curl -fsSL "${URL}" -o "${TMP}"

if [[ ! -s "${TMP}" ]]; then
  echo "ERROR: download came back empty. Check the export URL." >&2
  exit 1
fi

if ! head -1 "${TMP}" | grep -qi 'en'; then
  echo "WARNING: the downloaded file doesn't look like a glossary CSV (unexpected header)." >&2
  echo "First line: $(head -1 "${TMP}")" >&2
fi

mv "${TMP}" "${TARGET}"
trap - EXIT

date +%F > "${STAMP}"

echo "Glossary updated: ${TARGET}"
echo "Lines: $(wc -l < "${TARGET}" | tr -d ' ')"
echo "Timestamp: $(cat "${STAMP}")"
