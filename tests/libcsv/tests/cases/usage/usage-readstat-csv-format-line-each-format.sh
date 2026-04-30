#!/usr/bin/env bash
# @testcase: usage-readstat-csv-format-line-each-format
# @title: readstat summary Format line content for each output format
# @description: Builds a CSV through DTA and then produces SAV, ZSAV, XPT, and SAS7BDAT files from that intermediate DTA, captures the readstat summary for each one, and verifies the leading "Format: ..." line carries the format-specific descriptor (Stata DTA, SPSS SAV, SPSS compressed ZSAV, SAS XPORT, SAS7BDAT) so the wrong format cannot be silently substituted.
# @timeout: 240
# @tags: usage, csv, summary, format
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
alpha,1
beta,2
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

# Build the DTA once, then derive the four other formats from it.
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" "$tmpdir/out.sav"
readstat "$tmpdir/out.dta" "$tmpdir/out.zsav"
readstat "$tmpdir/out.dta" "$tmpdir/out.xpt"
readstat "$tmpdir/out.dta" "$tmpdir/out.sas7bdat"

declare -A format_descriptor=(
  [dta]='Stata binary file (DTA)'
  [sav]='SPSS binary file (SAV)'
  [zsav]='SPSS compressed binary file (ZSAV)'
  [xpt]='SAS transport file (XPORT)'
  [sas7bdat]='SAS data file (SAS7BDAT)'
)

# For each format: the summary must carry its own descriptor and must NOT
# carry any other format's descriptor.
for ext in dta sav zsav xpt sas7bdat; do
  readstat "$tmpdir/out.$ext" >"$tmpdir/$ext.summary"
  expected="Format: ${format_descriptor[$ext]}"
  validator_assert_contains "$tmpdir/$ext.summary" "$expected"

  for other in dta sav zsav xpt sas7bdat; do
    [[ "$other" == "$ext" ]] && continue
    other_desc="${format_descriptor[$other]}"
    if grep -F -- "Format: $other_desc" "$tmpdir/$ext.summary" >/dev/null; then
      printf 'summary for .%s leaked descriptor for .%s: %s\n' \
        "$ext" "$other" "$other_desc" >&2
      cat "$tmpdir/$ext.summary" >&2
      exit 1
    fi
  done

  # Every summary must agree on the column count. (XPORT writers report
  # `Rows: -1` because the row count is not stored in the XPORT header.)
  validator_assert_contains "$tmpdir/$ext.summary" 'Columns: 2'
  if [[ "$ext" != "xpt" ]]; then
    validator_assert_contains "$tmpdir/$ext.summary" 'Rows: 2'
  else
    validator_assert_contains "$tmpdir/$ext.summary" 'Rows: -1'
  fi
done
