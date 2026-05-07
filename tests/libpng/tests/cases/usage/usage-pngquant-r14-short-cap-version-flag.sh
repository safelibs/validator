#!/usr/bin/env bash
# @testcase: usage-pngquant-r14-short-cap-version-flag
# @title: pngquant -V short flag prints the version banner and exits successfully
# @description: Invokes pngquant -V (the documented short alias of --version) and verifies the program prints a recognisable version banner on stdout and exits 0 — locking in that the uppercase short version flag is functional on Ubuntu 24.04 pngquant 2.18.0, distinct from the lowercase -v which controls verbosity.
# @timeout: 60
# @tags: usage, image, png, cli, version
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

pngquant -V >"$tmpdir/stdout" 2>"$tmpdir/stderr"

# Banner must contain a dotted version triple like 2.18.0.
grep -E '[0-9]+\.[0-9]+\.[0-9]+' "$tmpdir/stdout" >/dev/null || {
  printf 'pngquant -V did not print a recognisable version banner on stdout\n' >&2
  cat "$tmpdir/stdout" >&2
  exit 1
}
# On Ubuntu 24.04 the banner is exactly one short line.
lines=$(wc -l <"$tmpdir/stdout")
[[ "$lines" -le 2 ]] || {
  printf 'pngquant -V emitted unexpectedly many stdout lines: %s\n' "$lines" >&2
  cat "$tmpdir/stdout" >&2
  exit 1
}
