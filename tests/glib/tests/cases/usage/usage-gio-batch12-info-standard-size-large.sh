#!/usr/bin/env bash
# @testcase: usage-gio-batch12-info-standard-size-large
# @title: gio info reports correct standard::size for 1MB file
# @description: Writes a 1MB binary file and verifies "gio info -a standard::size" reports exactly 1048576.
# @timeout: 60
# @tags: usage, gio, info
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

dd if=/dev/zero of="$tmpdir/big.bin" bs=1024 count=1024 2>/dev/null
gio info -a standard::size "$tmpdir/big.bin" >"$tmpdir/out.txt"
grep -E 'standard::size:[[:space:]]*1048576' "$tmpdir/out.txt" >/dev/null
