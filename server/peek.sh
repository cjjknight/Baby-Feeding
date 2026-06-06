#!/usr/bin/env bash
#
# peek.sh — print the live shared baby log (feedings + diapers) in local time.
#
#   ./peek.sh                 # default family
#   ./peek.sh <family_id>     # a specific family
#
# This reads the live D1 database. To FIX an entry so the change reaches both
# phones, do NOT hard-DELETE — the apps only learn about removals via tombstones.
# Instead set deleted=1 and bump updated_at so the next sync picks it up:
#
#   NOW=$(($(date +%s)*1000))
#   npx wrangler d1 execute baby-feeding --remote --command \
#     "UPDATE feedings SET deleted=1, updated_at=$NOW WHERE id='<full-id>'"
#   # or correct a time:
#   npx wrangler d1 execute baby-feeding --remote --command \
#     "UPDATE diapers SET occurred_at=<epoch_ms>, updated_at=$NOW WHERE id='<full-id>'"
#
# (Hard DELETE is only safe for wiping test rows that never reached a phone.)
#
set -euo pipefail
cd "$(dirname "$0")"
FAM="${1:-f64fb73f-398f-4359-8cc7-761556dbfe22}"

# Pretty-print wrangler's --json rows as compact "key=value" lines.
fmt() {
  node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{let rows;try{rows=(JSON.parse(s)[0]||{}).results||[]}catch(e){rows=[]}if(!rows.length){console.log("  (none)");return}for(const r of rows)console.log("  "+Object.entries(r).map(([k,v])=>k+"="+v).join("   "))})'
}

echo "== FEEDINGS (newest first) =="
npx wrangler d1 execute baby-feeding --remote --json --command \
  "SELECT id, datetime(fed_at/1000,'unixepoch','localtime') AS time_local, \
          CASE deleted WHEN 1 THEN 'deleted' ELSE 'ok' END AS status \
     FROM feedings WHERE family_id='$FAM' ORDER BY fed_at DESC LIMIT 50" 2>/dev/null | fmt

echo
echo "== DIAPERS (newest first) =="
npx wrangler d1 execute baby-feeding --remote --json --command \
  "SELECT id, kind, datetime(occurred_at/1000,'unixepoch','localtime') AS time_local, \
          CASE deleted WHEN 1 THEN 'deleted' ELSE 'ok' END AS status \
     FROM diapers WHERE family_id='$FAM' ORDER BY occurred_at DESC LIMIT 50" 2>/dev/null | fmt
