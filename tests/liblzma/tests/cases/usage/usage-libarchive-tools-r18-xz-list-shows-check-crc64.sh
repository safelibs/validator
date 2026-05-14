#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r18-xz-list-shows-check-crc64
# @title: xz --list -vv on a default-compressed file shows the CRC64 integrity check
# @description: Compresses a payload with default xz settings and asserts xz --list -vv reports a CRC64 integrity check in its detailed listing, pinning the default integrity-check type emitted by the liblzma encoder.
# @timeout: 60
# @tags: usage, xz, list, crc64, r18
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r18 crc64 listing payload\n' >"$tmpdir/in.txt"
xz -c "$tmpdir/in.txt" >"$tmpdir/in.xz"

xz --list -vv "$tmpdir/in.xz" >"$tmpdir/listing.txt"
validator_assert_contains "$tmpdir/listing.txt" 'CRC64'
