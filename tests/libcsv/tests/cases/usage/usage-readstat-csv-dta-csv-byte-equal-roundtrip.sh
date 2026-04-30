#!/usr/bin/env bash
# @testcase: usage-readstat-csv-dta-csv-byte-equal-roundtrip
# @title: readstat CSV through DTA and back is byte-stable across two passes
# @description: Round-trips a CSV through DTA twice — once for a reference readback CSV and once for a second readback CSV — and verifies the two readback CSVs are byte-for-byte identical via cmp, then computes a SHA-256 of each and verifies the digests match exactly, proving the DTA roundtrip is deterministic and yields identical bytes on a fresh invocation.
# @timeout: 240
# @tags: usage, csv, roundtrip, byte-equality
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
delta,4
epsilon,5
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

# First pass: CSV -> DTA -> CSV.
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/passA.dta"
validator_require_file "$tmpdir/passA.dta"
readstat "$tmpdir/passA.dta" - >"$tmpdir/readback_A.csv"

# Second pass: same input, fresh DTA, fresh readback.
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/passB.dta"
validator_require_file "$tmpdir/passB.dta"
readstat "$tmpdir/passB.dta" - >"$tmpdir/readback_B.csv"

# Each readback must be non-empty and shape-correct: header + 5 rows.
for f in "$tmpdir/readback_A.csv" "$tmpdir/readback_B.csv"; do
  [[ -s "$f" ]] || {
    printf 'readback file is empty: %s\n' "$f" >&2
    exit 1
  }
  total=$(wc -l <"$f")
  [[ "$total" == "6" ]] || {
    printf 'expected 6 lines in %s, got %s\n' "$f" "$total" >&2
    cat "$f" >&2
    exit 1
  }
done

# Strong byte equality via cmp (no context, just exit status).
if ! cmp -s "$tmpdir/readback_A.csv" "$tmpdir/readback_B.csv"; then
  printf 'readback CSVs differ between two passes\n' >&2
  diff -u "$tmpdir/readback_A.csv" "$tmpdir/readback_B.csv" >&2 || true
  exit 1
fi

# Independent corroboration via SHA-256 digest match.
hashA=$(sha256sum "$tmpdir/readback_A.csv" | awk '{print $1}')
hashB=$(sha256sum "$tmpdir/readback_B.csv" | awk '{print $1}')
[[ "$hashA" == "$hashB" ]] || {
  printf 'sha256 mismatch: %s vs %s\n' "$hashA" "$hashB" >&2
  exit 1
}

# And byte length must match (defence in depth against newline weirdness).
sizeA=$(wc -c <"$tmpdir/readback_A.csv")
sizeB=$(wc -c <"$tmpdir/readback_B.csv")
[[ "$sizeA" == "$sizeB" ]] || {
  printf 'byte length mismatch: %s vs %s\n' "$sizeA" "$sizeB" >&2
  exit 1
}

# Sanity: each readback contains the expected rows.
for row in '"alpha",1.000000' '"beta",2.000000' '"gamma",3.000000' '"delta",4.000000' '"epsilon",5.000000'; do
  validator_assert_contains "$tmpdir/readback_A.csv" "$row"
  validator_assert_contains "$tmpdir/readback_B.csv" "$row"
done
