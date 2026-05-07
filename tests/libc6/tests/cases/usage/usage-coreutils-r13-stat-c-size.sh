#!/usr/bin/env bash
# @testcase: usage-coreutils-r13-stat-c-size
# @title: coreutils stat -c %s reports exact byte size via libc stat
# @description: Writes a file with a known byte count, runs stat -c %s on it, and asserts the reported size matches the byte count returned by libc stat.
# @timeout: 60
# @tags: usage, coreutils, stat
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 256 bytes of fixed payload.
LC_ALL=C printf '%.0sX' {1..256} >"$tmpdir/blob.bin"
[[ "$(wc -c <"$tmpdir/blob.bin")" -eq 256 ]]

got=$(LC_ALL=C stat -c '%s' "$tmpdir/blob.bin")
[[ "$got" == "256" ]]
