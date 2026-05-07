#!/usr/bin/env bash
# @testcase: usage-pngquant-r13-short-v-version-flag
# @title: pngquant -V short flag prints the version banner
# @description: Runs pngquant with the short -V flag and verifies the printed banner matches a "MAJOR.MINOR.PATCH (Month YYYY)" form on stdout, locking in that the short -V alias of --version returns a structured version string and exits successfully — distinguishing -V from the existing --version long-form test.
# @timeout: 60
# @tags: usage, image, png, cli, version
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

pngquant -V >"$tmpdir/v.out" 2>"$tmpdir/v.err"

# Output must contain a semantic-style version followed by a parenthesised month/year.
grep -E '^[0-9]+\.[0-9]+\.[0-9]+ \([A-Z][a-z]+ [0-9]{4}\)' "$tmpdir/v.out" >/dev/null || {
  printf 'pngquant -V output did not match version banner form\n' >&2
  cat "$tmpdir/v.out" >&2
  exit 1
}

# stderr must be empty for a successful version query.
if [[ -s "$tmpdir/v.err" ]]; then
  printf 'pngquant -V wrote to stderr unexpectedly\n' >&2
  cat "$tmpdir/v.err" >&2
  exit 1
fi
