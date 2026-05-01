#!/usr/bin/env bash
# @testcase: usage-readstat-no-args-emits-usage
# @title: readstat without arguments prints usage banner
# @description: Invokes readstat with no positional arguments, captures stdout and stderr, and verifies the binary prints the standard banner including the version line, the supported input extensions list, and the convert syntax describing input and output filenames.
# @timeout: 60
# @tags: usage, csv, cli, banner
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

readstat </dev/null >"$tmpdir/stdout" 2>"$tmpdir/stderr" || true
cat "$tmpdir/stdout" "$tmpdir/stderr" >"$tmpdir/all"

# The banner must include the version header and convert/usage instructions.
validator_assert_contains "$tmpdir/all" 'ReadStat version'
validator_assert_contains "$tmpdir/all" 'Convert a file:'
validator_assert_contains "$tmpdir/all" 'input.(dta|por|sav|sas7bdat|xpt|zsav)'

# Banner must mention all six supported input file extensions in the listing.
for ext in dta por sav sas7bdat xpt zsav; do
  if ! grep -F -- "$ext" "$tmpdir/all" >/dev/null; then
    printf 'banner missing extension reference: %s\n' "$ext" >&2
    cat "$tmpdir/all" >&2
    exit 1
  fi
done
