#!/usr/bin/env bash
# @testcase: usage-bash-batch12-printf-strftime-iso-time
# @title: bash printf %(format)T uses strftime via libc
# @description: Uses bash's printf %(format)T to render a fixed epoch via libc strftime in UTC and verifies the formatted output equals the expected ISO 8601 string.
# @timeout: 60
# @tags: usage, bash, time
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Epoch 1700000000 = 2023-11-14T22:13:20Z
TZ=UTC printf '%(%Y-%m-%dT%H:%M:%SZ)T\n' 1700000000 >"$tmpdir/out.txt"
got=$(cat "$tmpdir/out.txt")
[[ "$got" == "2023-11-14T22:13:20Z" ]]
