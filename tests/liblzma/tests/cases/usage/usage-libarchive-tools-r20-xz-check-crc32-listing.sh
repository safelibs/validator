#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r20-xz-check-crc32-listing
# @title: xz --check=crc32 stream lists CRC32 as the integrity check
# @description: Compresses a payload with xz --check=crc32, runs xz --list -vv on the result, and asserts the listing reports the CRC32 integrity check, pinning the explicit check-selection path distinct from the default CRC64 and from the SHA-256/none variants.
# @timeout: 60
# @tags: usage, xz, check, crc32, list, r20
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r20 xz crc32 check payload\n' >"$tmpdir/in.txt"
xz --check=crc32 -c "$tmpdir/in.txt" >"$tmpdir/in.xz"

xz --list -vv "$tmpdir/in.xz" >"$tmpdir/listing.txt"
validator_require_file "$tmpdir/listing.txt"
grep -Eiq 'CRC32' "$tmpdir/listing.txt"
