#!/usr/bin/env bash
# @testcase: usage-python3-batch12-time-strftime-utc
# @title: python3 time.strftime via libc strftime in UTC
# @description: Uses python3 time.strftime to format a fixed epoch in UTC via libc strftime and verifies the output equals the expected ISO 8601 string.
# @timeout: 60
# @tags: usage, python, time
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

TZ=UTC python3 -c '
import time
print(time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(1700000000)))
' >"$tmpdir/out.txt"
got=$(cat "$tmpdir/out.txt")
[[ "$got" == "2023-11-14T22:13:20Z" ]]
