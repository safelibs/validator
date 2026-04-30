#!/usr/bin/env bash
# @testcase: usage-findutils-printf-mtime
# @title: findutils printf epoch mtime
# @description: Sets a fixed mtime on a fixture file and uses find -printf %T@ to read the epoch timestamp back, verifying the value matches.
# @timeout: 180
# @tags: usage, findutils, filesystem
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-findutils-printf-mtime"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/tree"
target="$tmpdir/tree/payload.txt"
printf 'mtime probe\n' >"$target"

# 2026-01-15 12:00:00 UTC = 1768521600
touch -d '@1768521600' "$target"

find "$tmpdir/tree" -type f -name 'payload.txt' -printf '%f|%T@\n' >"$tmpdir/out"

line=$(cat "$tmpdir/out")
filename=${line%%|*}
ts=${line##*|}
# %T@ prints epoch with fractional seconds; the integer part must match.
ts_int=${ts%%.*}

if [[ "$filename" != 'payload.txt' ]]; then
  printf 'unexpected filename in find -printf output: %s\n' "$filename" >&2
  exit 1
fi
if [[ "$ts_int" != '1768521600' ]]; then
  printf 'find -printf %%T@ epoch mismatch: %s (line: %s)\n' "$ts_int" "$line" >&2
  exit 1
fi
