#!/usr/bin/env bash
set -u

BASE_URL="http://127.0.0.1:3000"
KEY="X"
CASES_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../tests/reverse-regression-cases.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-url)
      BASE_URL="$2"
      shift 2
      ;;
    --key)
      KEY="$2"
      shift 2
      ;;
    --cases)
      CASES_PATH="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  echo "Missing dependency: jq" >&2
  exit 2
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "Missing dependency: curl" >&2
  exit 2
fi

if [[ ! -f "$CASES_PATH" ]]; then
  echo "Cases file not found: $CASES_PATH" >&2
  exit 2
fi

BASE_URL="${BASE_URL%/}"
failures=0

case_count=$(jq '.cases | length' "$CASES_PATH")

for ((i=0; i<case_count; i++)); do
  name=$(jq -r ".cases[$i].name" "$CASES_PATH")
  lat=$(jq -r ".cases[$i].lat" "$CASES_PATH")
  lon=$(jq -r ".cases[$i].lon" "$CASES_PATH")
  url="$BASE_URL/reverse?lat=$lat&lon=$lon&key=$KEY"

  echo
  echo "==== $name ===="
  echo "$lat,$lon"

  response=$(curl -fsS --max-time 10 "$url" 2>/tmp/check-reverse-regression-curl.err)
  curl_status=$?
  if [[ $curl_status -ne 0 ]]; then
    echo "FAIL request: $(cat /tmp/check-reverse-regression-curl.err)"
    failures=$((failures + 1))
    continue
  fi

  echo "display_name: $(jq -r '.display_name // ""' <<<"$response")"
  echo "city: $(jq -r '.address.city // ""' <<<"$response")"
  echo "state: $(jq -r '.address.state // ""' <<<"$response")"
  echo "suburb: $(jq -r '.address.suburb // ""' <<<"$response")"

  while IFS= read -r field; do
    [[ -z "$field" ]] && continue
    expected=$(jq -r --arg field "$field" ".cases[$i].expected[$field]" "$CASES_PATH")
    actual=$(jq -r --arg field "$field" ".address[$field] // \"\"" <<<"$response")

    if [[ "$actual" != "$expected" ]]; then
      echo "FAIL $field: expected '$expected', got '$actual'"
      failures=$((failures + 1))
    fi
  done < <(jq -r ".cases[$i].expected // {} | keys[]" "$CASES_PATH")

  while IFS= read -r field; do
    [[ -z "$field" ]] && continue
    not_expected=$(jq -r --arg field "$field" ".cases[$i].not_expected[$field]" "$CASES_PATH")
    actual=$(jq -r --arg field "$field" ".address[$field] // \"\"" <<<"$response")

    if [[ "$actual" == "$not_expected" ]]; then
      echo "FAIL $field: got forbidden value '$not_expected'"
      failures=$((failures + 1))
    fi
  done < <(jq -r ".cases[$i].not_expected // {} | keys[]" "$CASES_PATH")
done

echo
echo "=============================="

if [[ $failures -gt 0 ]]; then
  echo "REGRESSION FAILED: $failures failure(s)"
  exit 1
fi

echo "REGRESSION PASSED"
exit 0
