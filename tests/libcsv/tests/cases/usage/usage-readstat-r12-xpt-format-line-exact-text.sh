#!/usr/bin/env bash
# @testcase: usage-readstat-r12-xpt-format-line-exact-text
# @title: readstat XPT summary reports Format: SAS transport file (XPORT)
# @description: Builds an XPT from a CSV via DTA and verifies the readstat summary contains the precise "Format: SAS transport file (XPORT)" line, locking in the literal format-line text used by the readstat metadata view for XPT files on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, csv, xpt, format
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,name
1,alice
2,bob
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"STRING","name":"name","label":"Name"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.xpt"
readstat "$tmpdir/out.xpt" >"$tmpdir/summary"

grep -E '^Format: SAS transport file \(XPORT\)$' "$tmpdir/summary" >/dev/null || {
  printf 'XPT summary missing exact Format line\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
# Exactly one Format line per summary.
count=$(grep -cE '^Format: ' "$tmpdir/summary")
[[ "$count" == "1" ]] || { printf 'expected exactly one Format line, got %s\n' "$count" >&2; cat "$tmpdir/summary" >&2; exit 1; }
# Format must not refer to any of the other formats.
for other in 'Stata' 'SPSS' 'SAS data file' 'XLSX'; do
  if grep -F "Format: " "$tmpdir/summary" | grep -F "$other" >/dev/null; then
    printf 'XPT format line unexpectedly mentions %s\n' "$other" >&2
    cat "$tmpdir/summary" >&2
    exit 1
  fi
done
