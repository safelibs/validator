#!/usr/bin/env bash
# @testcase: usage-jshon-r6-tab-newline-string-values
# @title: jshon -u decodes string values containing escaped tabs and newlines
# @description: Reads two object fields whose JSON-encoded string values contain escape sequences \t (tab) and \n (newline), then verifies that jshon -u emits the decoded literal control character so the byte length and surrounding text match expectations.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r6-tab-newline-string-values"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Tab escape inside a string value.
printf '%s' '{"tabbed":"left\tright"}' | jshon -e tabbed -u >"$tmpdir/tab"

# Output must contain a literal TAB byte separating "left" and "right".
expected_tab=$'left\tright'
if ! grep -Fxq -- "$expected_tab" "$tmpdir/tab"; then
  printf 'expected literal tab between left and right, got:\n' >&2
  od -c "$tmpdir/tab" >&2
  exit 1
fi

# Byte length reported by -l is 10: "left" (4) + TAB (1) + "right" (5) = 10.
printf '%s' '{"tabbed":"left\tright"}' | jshon -e tabbed -l >"$tmpdir/tablen"
if ! grep -Fxq -- '10' "$tmpdir/tablen"; then
  printf 'expected length 10 for "left\\tright", got:\n' >&2
  cat "$tmpdir/tablen" >&2
  exit 1
fi

# Newline escape: emitted with a literal LF byte, so output spans two lines.
printf '%s' '{"two":"first\nsecond"}' | jshon -e two -u >"$tmpdir/nl"

linecount=$(wc -l <"$tmpdir/nl")
# "first\nsecond" decodes to "first<LF>second" then jshon -u adds a trailing LF,
# so the file holds two complete lines as counted by wc -l.
if [[ "$linecount" -ne 2 ]]; then
  printf 'expected 2 lines after newline decode, got %s:\n' "$linecount" >&2
  od -c "$tmpdir/nl" >&2
  exit 1
fi

# Both halves must appear independently.
if ! grep -Fxq -- 'first' "$tmpdir/nl"; then
  printf 'expected first line "first", got:\n' >&2
  cat "$tmpdir/nl" >&2
  exit 1
fi
if ! grep -Fxq -- 'second' "$tmpdir/nl"; then
  printf 'expected second line "second", got:\n' >&2
  cat "$tmpdir/nl" >&2
  exit 1
fi

# Byte length of "first\nsecond" is 12: 5 + 1 + 6.
printf '%s' '{"two":"first\nsecond"}' | jshon -e two -l >"$tmpdir/nllen"
if ! grep -Fxq -- '12' "$tmpdir/nllen"; then
  printf 'expected length 12 for "first\\nsecond", got:\n' >&2
  cat "$tmpdir/nllen" >&2
  exit 1
fi
