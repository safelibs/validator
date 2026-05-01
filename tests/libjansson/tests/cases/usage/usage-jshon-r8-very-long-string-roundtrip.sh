#!/usr/bin/env bash
# @testcase: usage-jshon-r8-very-long-string-roundtrip
# @title: jshon round-trips a 4000-character string value through unstring
# @description: Builds a JSON object whose value is a single ASCII string of 4000 X characters, parses it through jshon, extracts the value with -e -u, and verifies the unstring output is exactly 4000 bytes plus the trailing newline so libjansson preserves long string payloads without truncation, splitting, or escape expansion.
# @timeout: 180
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r8-very-long-string-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a 4000-character ASCII string of X's.
big=$(printf 'X%.0s' $(seq 1 4000))
big_len=${#big}
if [[ "$big_len" -ne 4000 ]]; then
  printf 'fixture build error: expected 4000-char string, got %s\n' "$big_len" >&2
  exit 1
fi

# Embed it in an object and write the JSON to a file.
printf '{"big":"%s","tag":"end"}' "$big" >"$tmpdir/in.json"

# Sanity: the document parses and reports two object keys.
jshon -F "$tmpdir/in.json" -l >"$tmpdir/len"
grep -Fxq -- '2' "$tmpdir/len" || {
  printf 'expected object length 2, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
}

# Round-trip the long string through -u.
jshon -F "$tmpdir/in.json" -e big -u >"$tmpdir/big-out"

# -u terminates output with a single newline; total bytes should be 4001.
bytes=$(wc -c <"$tmpdir/big-out")
if [[ "$bytes" -ne 4001 ]]; then
  printf 'expected 4001 bytes (4000 + newline) from -u, got %s\n' "$bytes" >&2
  exit 1
fi

# All 4000 payload bytes must be the literal X.
xcount=$(tr -d '\n' <"$tmpdir/big-out" | tr -d 'X' | wc -c)
if [[ "$xcount" -ne 0 ]]; then
  printf 'expected only X characters in payload, found %s non-X bytes\n' "$xcount" >&2
  exit 1
fi

# Sibling key still extractable.
jshon -F "$tmpdir/in.json" -e tag -u >"$tmpdir/tag"
grep -Fxq -- 'end' "$tmpdir/tag" || {
  printf 'expected sibling tag=end, got:\n' >&2
  cat "$tmpdir/tag" >&2
  exit 1
}
