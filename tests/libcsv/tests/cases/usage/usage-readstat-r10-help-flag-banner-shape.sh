#!/usr/bin/env bash
# @testcase: usage-readstat-r10-help-flag-banner-shape
# @title: readstat -h prints the full help banner with all conversion modes
# @description: Invokes readstat with the -h flag and verifies the help banner enumerates every documented mode of operation including the metadata view, the CSV-to-stdout dump, the format-to-format conversion, the CSV+JSON metadata conversion, the CSV+command-file conversion, and the SAS7BDAT-with-catalog conversion, ensuring no documented entry point disappears from the help text.
# @timeout: 60
# @tags: usage, csv, cli, help
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

readstat -h >"$tmpdir/stdout" 2>"$tmpdir/stderr"
cat "$tmpdir/stdout" "$tmpdir/stderr" >"$tmpdir/all"

# All six documented mode descriptions must appear in the help banner.
validator_assert_contains "$tmpdir/all" 'ReadStat version'
validator_assert_contains "$tmpdir/all" "View a file's metadata"
validator_assert_contains "$tmpdir/all" 'Read a file, and write CSV to standard out'
validator_assert_contains "$tmpdir/all" 'Convert a file'
validator_assert_contains "$tmpdir/all" 'Convert a CSV file with column metadata stored in a separate JSON file'
validator_assert_contains "$tmpdir/all" 'Convert a text file with column metadata stored in a SAS command files'
validator_assert_contains "$tmpdir/all" 'Convert a SAS7BDAT file with value labels stored in a separate SAS catalog file'

# All six metadata file extensions for the multi-mode helper must appear.
for token in 'metadata.json' '(dct|sas|sps)' 'catalog.sas7bcat'; do
  if ! grep -F -- "$token" "$tmpdir/all" >/dev/null; then
    printf 'help banner missing token: %s\n' "$token" >&2
    cat "$tmpdir/all" >&2
    exit 1
  fi
done
