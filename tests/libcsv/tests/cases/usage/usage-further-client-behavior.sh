#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-readstat-dta-unicode-string)
    cat >"$tmpdir/in.csv" <<'CSV'
name
café
CSV
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
    readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
    validator_assert_contains "$tmpdir/out.csv" 'café'
    ;;
  usage-readstat-sav-unicode-string)
    cat >"$tmpdir/in.csv" <<'CSV'
name
café
CSV
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"STRING","name":"name","label":"Name"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
    readstat "$tmpdir/out.sav" - >"$tmpdir/out.csv"
    validator_assert_contains "$tmpdir/out.csv" 'café'
    ;;
  usage-readstat-dta-tab-note)
    printf 'note\n"left\tright"\n' >"$tmpdir/in.csv"
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"note","label":"Note"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
    readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
    python3 - <<'PYCASE' "$tmpdir/out.csv"
from pathlib import Path
import sys
text = Path(sys.argv[1]).read_text(encoding='utf-8')
assert '\t' in text
PYCASE
    ;;
  usage-readstat-sav-tab-note)
    printf 'note\n"left\tright"\n' >"$tmpdir/in.csv"
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"STRING","name":"note","label":"Note"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
    readstat "$tmpdir/out.sav" - >"$tmpdir/out.csv"
    python3 - <<'PYCASE' "$tmpdir/out.csv"
from pathlib import Path
import sys
text = Path(sys.argv[1]).read_text(encoding='utf-8')
assert '\t' in text
PYCASE
    ;;
  usage-readstat-dta-scientific-number)
    cat >"$tmpdir/in.csv" <<'CSV'
value
1.25e3
CSV
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
    readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
    validator_assert_contains "$tmpdir/out.csv" '1250.000000'
    ;;
  usage-readstat-sav-scientific-number)
    cat >"$tmpdir/in.csv" <<'CSV'
value
1.25e3
CSV
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
    readstat "$tmpdir/out.sav" - >"$tmpdir/out.csv"
    validator_assert_contains "$tmpdir/out.csv" '1250.000000'
    ;;
  usage-readstat-dta-single-column)
    cat >"$tmpdir/in.csv" <<'CSV'
name
alpha
beta
CSV
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
    readstat "$tmpdir/out.dta" >"$tmpdir/summary"
    validator_assert_contains "$tmpdir/summary" 'Columns: 1'
    ;;
  usage-readstat-sav-single-column)
    cat >"$tmpdir/in.csv" <<'CSV'
name
alpha
beta
CSV
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"STRING","name":"name","label":"Name"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
    readstat "$tmpdir/out.sav" >"$tmpdir/summary"
    validator_assert_contains "$tmpdir/summary" 'Columns: 1'
    ;;
  usage-readstat-dta-mixed-decimal-sign)
    cat >"$tmpdir/in.csv" <<'CSV'
value
-1.5
2.75
CSV
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
    readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
    validator_assert_contains "$tmpdir/out.csv" '-1.500000'
    validator_assert_contains "$tmpdir/out.csv" '2.750000'
    ;;
  usage-readstat-sav-mixed-decimal-sign)
    cat >"$tmpdir/in.csv" <<'CSV'
value
-1.5
2.75
CSV
    cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON
    readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
    readstat "$tmpdir/out.sav" - >"$tmpdir/out.csv"
    validator_assert_contains "$tmpdir/out.csv" '-1.500000'
    validator_assert_contains "$tmpdir/out.csv" '2.750000'
    ;;
  *)
    printf 'unknown libcsv further usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
