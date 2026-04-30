#!/usr/bin/env bash
# @testcase: usage-readstat-csv-format-version-extraction
# @title: readstat extracts Format version line across DTA SAV ZSAV SAS7BDAT formats
# @description: Builds a CSV through DTA and derives SAV, ZSAV, and SAS7BDAT files from that intermediate, captures each summary, extracts the trailing integer from the "Format version:" line with sed, and verifies that for every format the extracted value parses as a positive integer rather than being missing or non-numeric, locking in that the version field is structurally well-formed across the four formats that report it.
# @timeout: 240
# @tags: usage, csv, summary, format, version
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
alpha,1
beta,2
gamma,3
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

# Build DTA, then derive each downstream format from it.
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" "$tmpdir/out.sav"
readstat "$tmpdir/out.dta" "$tmpdir/out.zsav"
readstat "$tmpdir/out.dta" "$tmpdir/out.sas7bdat"

extract_version() {
  local summary=$1
  # Pull the trailing integer from the "Format version: NNN" line.
  sed -n 's/^Format version: \([0-9][0-9]*\)$/\1/p' "$summary"
}

for ext in dta sav zsav sas7bdat; do
  validator_require_file "$tmpdir/out.$ext"
  readstat "$tmpdir/out.$ext" >"$tmpdir/$ext.summary"

  # The "Format version:" line must be present.
  if ! grep -E '^Format version: [0-9]+$' "$tmpdir/$ext.summary" >/dev/null; then
    printf 'missing or malformed Format version line for .%s\n' "$ext" >&2
    cat "$tmpdir/$ext.summary" >&2
    exit 1
  fi

  version=$(extract_version "$tmpdir/$ext.summary")
  [[ -n "$version" ]] || {
    printf 'failed to extract version for .%s\n' "$ext" >&2
    cat "$tmpdir/$ext.summary" >&2
    exit 1
  }

  # Extracted value must be a positive integer.
  if ! [[ "$version" =~ ^[0-9]+$ ]]; then
    printf 'non-numeric extracted version for .%s: %s\n' "$ext" "$version" >&2
    exit 1
  fi
  if (( version <= 0 )); then
    printf 'non-positive extracted version for .%s: %s\n' "$ext" "$version" >&2
    exit 1
  fi

  # Exactly one Format version line per summary.
  count=$(grep -cE '^Format version: [0-9]+$' "$tmpdir/$ext.summary")
  [[ "$count" == "1" ]] || {
    printf 'expected exactly one Format version line for .%s, got %s\n' "$ext" "$count" >&2
    exit 1
  }
done

# Every captured summary also must agree on the column count.
for ext in dta sav zsav sas7bdat; do
  validator_assert_contains "$tmpdir/$ext.summary" 'Columns: 2'
done
