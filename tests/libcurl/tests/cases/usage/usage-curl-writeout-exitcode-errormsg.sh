#!/usr/bin/env bash
# @testcase: usage-curl-writeout-exitcode-errormsg
# @title: curl -w %{exitcode}/%{errormsg} reports failure details
# @description: Forces a file:// open failure for a missing path and uses -w '%{exitcode}|%{errormsg}' to verify the writeout reports a non-zero libcurl exit code and a non-empty error message string.
# @timeout: 60
# @tags: usage, curl, file, writeout
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-writeout-exitcode-errormsg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

set +e
curl -sS -o /dev/null -w 'ec=%{exitcode}|msg=%{errormsg}\n' \
  "file://$tmpdir/no-such-file" >"$tmpdir/wo.txt" 2>"$tmpdir/err"
rc=$?
set -e

[[ $rc -ne 0 ]]
# exitcode should be 37 (couldn't open file) on Ubuntu 24.04 curl 8.5.0.
validator_assert_contains "$tmpdir/wo.txt" 'ec=37'
validator_assert_contains "$tmpdir/wo.txt" 'msg='
# errormsg should mention the file open failure.
grep -Eqi "couldn't open|open file|no such" "$tmpdir/wo.txt"
