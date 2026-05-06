#!/usr/bin/env bash
# @testcase: usage-readstat-r10-csv-table-label-null-when-unset
# @title: readstat reports Table label (null) when the JSON metadata supplies no label
# @description: Converts a CSV through DTA and SAV using a JSON metadata file that declares no top-level table label and verifies both readstat summaries emit the literal "Table label: (null)" line, locking in the canonical placeholder used by the CLI when no Stata or SPSS dataset label was supplied.
# @timeout: 120
# @tags: usage, csv, summary, table-label
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
key,val
alpha,1
beta,2
CSV

# Note: the metadata supplies variable labels but no top-level dataset label.
cat >"$tmpdir/meta_dta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"key","label":"K"},{"type":"NUMERIC","name":"val","label":"V"}]}
JSON

cat >"$tmpdir/meta_sav.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"STRING","name":"key","label":"K"},{"type":"NUMERIC","name":"val","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta_dta.json" "$tmpdir/out.dta"
readstat "$tmpdir/in.csv" "$tmpdir/meta_sav.json" "$tmpdir/out.sav"

for f in "$tmpdir/out.dta" "$tmpdir/out.sav"; do
  readstat "$f" >"$tmpdir/summary"
  if ! grep -E '^Table label: \(null\)$' "$tmpdir/summary" >/dev/null; then
    printf 'expected "Table label: (null)" line in %s summary\n' "$f" >&2
    cat "$tmpdir/summary" >&2
    exit 1
  fi
  # Exactly one Table label line per summary.
  count=$(grep -cE '^Table label: ' "$tmpdir/summary")
  [[ "$count" == "1" ]] || {
    printf 'expected exactly one Table label line, got %s\n' "$count" >&2
    cat "$tmpdir/summary" >&2
    exit 1
  }
done
