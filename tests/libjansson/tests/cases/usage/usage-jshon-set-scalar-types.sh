#!/usr/bin/env bash
# @testcase: usage-jshon-set-scalar-types
# @title: jshon set top-level scalar types
# @description: Uses jshon -n to load each JSON scalar shape (string, number, true, false, null) as the document and verifies the type label reported by -t.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-set-scalar-types"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# jshon's -n option only accepts numeric literals and the keywords
# true/false/null/array/object. Strings must be loaded with -s, which JSON-
# encodes the value, so -n is exercised against numbers and json keywords
# while -s is exercised against the string scalar.
probe_n_type() {
  local value=$1
  local expected=$2
  jshon -n "$value" -t >"$tmpdir/type"
  if ! grep -Fxq -- "$expected" "$tmpdir/type"; then
    printf 'expected type %s for -n value %s, got:\n' "$expected" "$value" >&2
    cat "$tmpdir/type" >&2
    exit 1
  fi
}

probe_n_type '42'    number
probe_n_type '3.14'  number
probe_n_type 'true'  bool
probe_n_type 'false' bool
probe_n_type 'null'  null

# -s pushes a JSON-encoded string and -t must call it 'string'.
jshon -s 'hello' -t >"$tmpdir/s-type"
grep -Fxq -- 'string' "$tmpdir/s-type" || {
  printf 'expected string type for -s hello, got:\n' >&2
  cat "$tmpdir/s-type" >&2
  exit 1
}

# Verify the unstring of a loaded string value round-trips exactly.
jshon -s 'hello' -u >"$tmpdir/u"
if ! grep -Fxq -- 'hello' "$tmpdir/u"; then
  printf 'expected hello, got:\n' >&2
  cat "$tmpdir/u" >&2
  exit 1
fi

# Verify the loaded number prints back as the same digits.
jshon -n '42' -u >"$tmpdir/n"
if ! grep -Fxq -- '42' "$tmpdir/n"; then
  printf 'expected 42, got:\n' >&2
  cat "$tmpdir/n" >&2
  exit 1
fi
