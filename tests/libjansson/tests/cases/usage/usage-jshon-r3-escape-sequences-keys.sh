#!/usr/bin/env bash
# @testcase: usage-jshon-r3-escape-sequences-keys
# @title: jshon -e on keys containing backslash, tab, and quote escape sequences
# @description: Constructs an object whose keys contain a JSON-escaped backslash, a JSON-escaped tab, and a JSON-escaped double quote, then asserts jshon -e accepts the decoded raw key strings and returns the matching values.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r3-escape-sequences-keys"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# JSON document where keys are: "back\\slash", "tab\there", "quote\"end"
# i.e. raw keys after JSON decoding are:
#   back\slash
#   tab<TAB>here
#   quote"end
cat >"$tmpdir/input.json" <<'EOF'
{"back\\slash":"v_back","tab\there":"v_tab","quote\"end":"v_quote"}
EOF

# Build the raw (decoded) key strings to pass to -e.
backslash_key='back\slash'
tab_key=$'tab\there'
quote_key='quote"end'

# Backslash key.
jshon -F "$tmpdir/input.json" -e "$backslash_key" -u >"$tmpdir/v-back"
if ! grep -Fxq -- 'v_back' "$tmpdir/v-back"; then
  printf 'expected v_back at backslash key, got:\n' >&2
  cat "$tmpdir/v-back" >&2
  exit 1
fi

# Tab key.
jshon -F "$tmpdir/input.json" -e "$tab_key" -u >"$tmpdir/v-tab"
if ! grep -Fxq -- 'v_tab' "$tmpdir/v-tab"; then
  printf 'expected v_tab at tab key, got:\n' >&2
  cat "$tmpdir/v-tab" >&2
  exit 1
fi

# Quote key.
jshon -F "$tmpdir/input.json" -e "$quote_key" -u >"$tmpdir/v-quote"
if ! grep -Fxq -- 'v_quote' "$tmpdir/v-quote"; then
  printf 'expected v_quote at quote key, got:\n' >&2
  cat "$tmpdir/v-quote" >&2
  exit 1
fi

# Object length must be exactly 3.
jshon -F "$tmpdir/input.json" -l >"$tmpdir/len"
grep -Fxq -- '3' "$tmpdir/len" || {
  printf 'expected length 3, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
}
