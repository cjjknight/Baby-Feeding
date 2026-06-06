#!/usr/bin/env bash
#
# smoke.sh — end-to-end check of the live sync API (feedings + diapers).
#
# Run after every deploy. Uses a unique throwaway family id and deletes its
# rows at the end, so it never touches the real family's log. Exits non-zero
# if any assertion fails.
#
#   ./smoke.sh                              # against the deployed Worker
#   BASE=http://localhost:8787 ./smoke.sh   # against `npm run dev`
#
set -uo pipefail
cd "$(dirname "$0")"

BASE="${BASE:-https://baby-feeding-sync.johnson-books.workers.dev}"
FAM="smoke-$(date +%s)-$$"
pass=0; fail=0

check() { # check <name> <expected-substring> <actual>
  if [[ "$3" == *"$2"* ]]; then
    echo "  ✓ $1"; pass=$((pass+1))
  else
    echo "  ✗ $1"; echo "      expected to contain: $2"; echo "      got: $3"; fail=$((fail+1))
  fi
}

post() { curl -s -X POST "$BASE/$1" -H 'content-type: application/json' -d "$2"; }
get()  { curl -s "$BASE/$1"; }

echo "Smoke test against $BASE  (family=$FAM)"

echo "[health]"
check "health ok" '"ok":true' "$(get api/health)"

echo "[feedings]"
check "create"        '"fed_at":1000'  "$(post api/feedings "$(printf '{"family":"%s","id":"f1","fed_at":1000,"updated_at":1000}' "$FAM")")"
check "list has f1"   '"id":"f1"'       "$(get "api/feedings?family=$FAM")"
check "edit newer"    '"fed_at":2000'   "$(post api/feedings "$(printf '{"family":"%s","id":"f1","fed_at":2000,"updated_at":2000}' "$FAM")")"
check "stale ignored" '"fed_at":2000'   "$(post api/feedings "$(printf '{"family":"%s","id":"f1","fed_at":9999,"updated_at":1500}' "$FAM")")"
check "tombstone"     '"deleted":true'  "$(post api/feedings "$(printf '{"family":"%s","id":"f1","fed_at":2000,"deleted":true,"updated_at":3000}' "$FAM")")"
check "missing fed_at rejected" 'required' "$(post api/feedings "$(printf '{"family":"%s","id":"f2"}' "$FAM")")"

echo "[diapers]"
check "create pee"    '"kind":"pee"'    "$(post api/diapers "$(printf '{"family":"%s","id":"d1","occurred_at":1000,"kind":"pee","updated_at":1000}' "$FAM")")"
check "create poop"   '"kind":"poop"'   "$(post api/diapers "$(printf '{"family":"%s","id":"d2","occurred_at":2000,"kind":"poop","updated_at":2000}' "$FAM")")"
check "list has both" '"id":"d2"'       "$(get "api/diapers?family=$FAM")"
check "bad kind rejected" 'pee'         "$(post api/diapers "$(printf '{"family":"%s","id":"d3","occurred_at":3000,"kind":"spit"}' "$FAM")")"
check "tombstone"     '"deleted":true'  "$(post api/diapers "$(printf '{"family":"%s","id":"d1","occurred_at":1000,"kind":"pee","deleted":true,"updated_at":3000}' "$FAM")")"

echo "[cleanup]"
npx wrangler d1 execute baby-feeding --remote --command \
  "DELETE FROM feedings WHERE family_id='$FAM'; DELETE FROM diapers WHERE family_id='$FAM'" >/dev/null 2>&1 \
  && echo "  ✓ test rows removed" || echo "  ! cleanup failed (family=$FAM left in D1)"

echo
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
