#!/usr/bin/env bash
# @testcase: usage-gio-r18-info-standard-size-512-bytes
# @title: gio info standard::size reports 512 for a known 512-byte file
# @description: Creates a tmpdir file containing exactly 512 bytes of zero padding via dd and asserts gio info -a standard::size emits the exact "standard::size: 512" attribute line, exercising the size attribute query at a non-trivial byte count distinct from prior small-file tests.
# @timeout: 60
# @tags: usage, gio, info, size, r18
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

dd if=/dev/zero of="$tmpdir/blob.bin" bs=512 count=1 status=none
gio info -a standard::size "$tmpdir/blob.bin" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'standard::size: 512'
