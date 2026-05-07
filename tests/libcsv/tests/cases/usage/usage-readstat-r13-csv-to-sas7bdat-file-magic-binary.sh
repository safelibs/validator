#!/usr/bin/env bash
# @testcase: usage-readstat-r13-csv-to-sas7bdat-file-magic-binary
# @title: readstat-produced SAS7BDAT contains the canonical SAS7BDAT magic in its header
# @description: Builds a SAS7BDAT from a CSV via DTA and asserts the first kilobyte of the output contains the canonical SAS7BDAT magic byte sequence (c2 ea 81 60 b3 14 11 cf bd 92 08 00 09 c7 31 8c), locking in that the readstat SAS7BDAT writer emits a byte-recognisable SAS data file rather than a CSV-shaped placeholder.
# @timeout: 60
# @tags: usage, csv, sas7bdat, magic
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
readstat "$tmpdir/mid.dta" "$tmpdir/out.sas7bdat"

# Canonical SAS7BDAT magic appears in the first kilobyte. Search for the
# 16-byte sequence within the binary header.
python3 - "$tmpdir/out.sas7bdat" <<'PY'
import sys

magic = bytes.fromhex('c2ea8160b31411cfbd92080009c7318c')
with open(sys.argv[1], 'rb') as f:
    head = f.read(1024)
if magic not in head:
    raise SystemExit(f'SAS7BDAT magic not found in first KiB: head={head[:64]!r}')
PY

# Sanity: the file is structurally not a CSV.
file "$tmpdir/out.sas7bdat" >"$tmpdir/file.txt"
if grep -E 'ASCII text|CSV' "$tmpdir/file.txt" >/dev/null; then
  printf 'file(1) classified SAS7BDAT output as text/CSV\n' >&2
  cat "$tmpdir/file.txt" >&2
  exit 1
fi
