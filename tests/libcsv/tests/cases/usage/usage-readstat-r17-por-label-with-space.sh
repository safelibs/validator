#!/usr/bin/env bash
# @testcase: usage-readstat-r17-por-label-with-space
# @title: readstat preserves a variable label containing an embedded space through SAV->POR
# @description: Builds a SAV file whose first variable label contains an embedded space, converts it to .por via readstat, then asserts the .por summary contains the literal space-bearing label text — locking in label preservation through the portable writer.
# @timeout: 120
# @tags: usage, csv, por, label
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,score
1,10
2,20
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"NUMERIC","name":"id","label":"Patient Id"},{"type":"NUMERIC","name":"score","label":"Survey Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.sav"
readstat "$tmpdir/mid.sav" "$tmpdir/out.por"
readstat "$tmpdir/out.por" >"$tmpdir/summary"

validator_assert_contains "$tmpdir/summary" 'Patient Id'
validator_assert_contains "$tmpdir/summary" 'Survey Score'
