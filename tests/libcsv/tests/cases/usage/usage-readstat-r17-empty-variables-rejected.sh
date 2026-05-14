#!/usr/bin/env bash
# @testcase: usage-readstat-r17-empty-variables-rejected
# @title: readstat exits non-zero when the metadata declares zero variables
# @description: Feeds readstat a CSV with a header and a row paired with a metadata JSON whose variables array is empty, asserting the invocation exits non-zero — locking in that the writer refuses to produce output when no variables are declared.
# @timeout: 60
# @tags: usage, csv, metadata, error
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
a,b
1,2
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[]}
JSON

set +e
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta" >"$tmpdir/log" 2>&1
rc=$?
set -e

[[ "$rc" -ne 0 ]] || {
    printf 'expected readstat to fail with empty variables list, got exit 0\n' >&2
    cat "$tmpdir/log" >&2
    exit 1
}
