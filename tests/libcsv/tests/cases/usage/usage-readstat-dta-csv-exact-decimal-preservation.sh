#!/usr/bin/env bash
# @testcase: usage-readstat-dta-csv-exact-decimal-preservation
# @title: readstat DTA to CSV preserves exact decimal representation
# @description: Builds a DTA from a CSV whose numeric column carries exactly representable binary decimals (0.5, 0.25, 0.125, 0.0625), then reads the DTA back to CSV twice — once into a reference file and once into a comparison file — and verifies the decimal cells are emitted in their exact canonical six-decimal form (0.500000, 0.250000, 0.125000, 0.062500), that the two readbacks are byte-identical, and that no value drifts into long-form scientific notation or extra digits.
# @timeout: 180
# @tags: usage, csv, decimal, exact, preservation
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Each value is exactly representable in IEEE 754 binary floating point:
# 0.5, 0.25, 0.125, 0.0625 are all powers of two, so they cannot drift.
cat >"$tmpdir/in.csv" <<'CSV'
name,score
half,0.5
quarter,0.25
eighth,0.125
sixteenth,0.0625
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

# Build the DTA once; readback it twice (independent invocations).
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
validator_require_file "$tmpdir/out.dta"

readstat "$tmpdir/out.dta" - >"$tmpdir/readback_1.csv"
readstat "$tmpdir/out.dta" - >"$tmpdir/readback_2.csv"

# Each readback must carry the exact canonical six-decimal forms.
for f in "$tmpdir/readback_1.csv" "$tmpdir/readback_2.csv"; do
  validator_assert_contains "$f" '"name","score"'
  validator_assert_contains "$f" '"half",0.500000'
  validator_assert_contains "$f" '"quarter",0.250000'
  validator_assert_contains "$f" '"eighth",0.125000'
  validator_assert_contains "$f" '"sixteenth",0.062500'

  # Forbid drifted long-form expansions or scientific notation.
  if grep -E '0\.500000[0-9]|0\.250000[0-9]|0\.125000[0-9]|0\.062500[0-9]|[0-9]e[+-]' "$f" >/dev/null; then
    printf 'value drifted away from exact representation in %s\n' "$f" >&2
    cat "$f" >&2
    exit 1
  fi
done

# The two readbacks of the same DTA must be byte-identical.
if ! cmp -s "$tmpdir/readback_1.csv" "$tmpdir/readback_2.csv"; then
  printf 'two readbacks of the same DTA differ\n' >&2
  diff -u "$tmpdir/readback_1.csv" "$tmpdir/readback_2.csv" >&2 || true
  exit 1
fi

# Each numeric cell must conform to the six-decimal pattern (no expansion).
for ln in 2 3 4 5; do
  cell=$(sed -n "${ln}p" "$tmpdir/readback_1.csv" | cut -d, -f2)
  if ! [[ "$cell" =~ ^0\.[0-9]{6}$ ]]; then
    printf 'line %s column2 does not match 0.NNNNNN pattern: %s\n' "$ln" "$cell" >&2
    exit 1
  fi
done

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 4'
