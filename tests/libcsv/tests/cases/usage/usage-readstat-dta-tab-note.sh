#!/usr/bin/env bash
# @testcase: usage-readstat-dta-tab-note
# @title: readstat DTA tab note
# @description: Converts a CSV field containing a tab to DTA with readstat and verifies the tab survives the round trip.
# @timeout: 180
# @tags: usage, csv, readstat
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-readstat-dta-tab-note"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

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
