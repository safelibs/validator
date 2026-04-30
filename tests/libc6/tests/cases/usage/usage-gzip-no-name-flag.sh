#!/usr/bin/env bash
# @testcase: usage-gzip-no-name-flag
# @title: gzip -n omits original name and timestamp
# @description: Compresses with gzip -n and inspects the gzip header bytes to confirm the FNAME flag is unset and mtime is zero.
# @timeout: 180
# @tags: usage, gzip, archive
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gzip-no-name-flag"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'gzip-no-name flag payload data\n' >"$tmpdir/payload.txt"
gzip -n -c "$tmpdir/payload.txt" >"$tmpdir/payload.gz"

# Header layout (RFC 1952): bytes 0..1 = 1f 8b, byte 3 = FLG, bytes 4..7 = MTIME (LE).
header_hex=$(od -An -N8 -tx1 "$tmpdir/payload.gz" | tr -d ' \n')
test "${header_hex:0:4}" = '1f8b'

flg_hex="${header_hex:6:2}"
flg=$((16#$flg_hex))
# FNAME bit is 0x08 - must be cleared with -n.
test $((flg & 0x08)) -eq 0

mtime_hex="${header_hex:8:8}"
test "$mtime_hex" = '00000000'

# Roundtrip sanity check.
gzip -dc "$tmpdir/payload.gz" >"$tmpdir/roundtrip"
diff "$tmpdir/payload.txt" "$tmpdir/roundtrip"
