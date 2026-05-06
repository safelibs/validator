#!/usr/bin/env bash
# @testcase: usage-coreutils-r10-date-utc-fixed-epoch-iso
# @title: date -u -d @<epoch> renders deterministic ISO-8601 via libc strftime
# @description: Renders a fixed UNIX epoch through date -u -d @1700000000 with an ISO 8601 format string and verifies the output equals the expected UTC timestamp emitted by libc strftime.
# @timeout: 60
# @tags: usage, coreutils, time
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

LC_ALL=C TZ=UTC date -u -d @1700000000 +'%Y-%m-%dT%H:%M:%SZ' >"$tmpdir/out.txt"
got=$(cat "$tmpdir/out.txt")
[[ "$got" == "2023-11-14T22:13:20Z" ]]
