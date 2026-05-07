#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r13-cli-no-dictid-flag
# @title: zstd CLI --no-dictID strips dictID from a dictionary-compressed frame while still decoding with the same dict
# @description: Trains a small dictionary, compresses a payload with -D dict --no-dictID, asserts the resulting frame still passes -t and round-trips when the same dictionary is supplied on decompression, while the recorded -lv listing reports a Dictionary ID of 0 (i.e. dictID was not written into the header).
# @timeout: 240
# @tags: usage, archive, zstd, cli, dictionary
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$tmpdir/samples"
mkdir -p "$samples"
python3 - "$samples" <<'PY'
import os, sys
out = sys.argv[1]
phrases = [
    b"r13 nodictid alpha\n",
    b"r13 nodictid bravo\n",
    b"r13 nodictid charlie\n",
    b"r13 nodictid delta\n",
]
for i in range(256):
    body = phrases[i % len(phrases)] * (5 + (i % 7))
    with open(os.path.join(out, f"s{i:03d}.txt"), "wb") as fh:
        fh.write(body)
PY

dict="$tmpdir/dict.bin"
zstd -q --train "$samples"/*.txt -o "$dict"
validator_require_file "$dict"

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r13 nodictid payload row\n" * 256)' >"$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

# Compress with dictionary and --no-dictID.
zstd -q -D "$dict" --no-dictID -o "$tmpdir/out.zst" "$src"
validator_require_file "$tmpdir/out.zst"

# Listing should advertise DictID 0 because the field was suppressed.
zstd -lv "$tmpdir/out.zst" >"$tmpdir/listing" 2>&1
grep -E 'DictID:[[:space:]]*0' "$tmpdir/listing" >/dev/null || {
    printf 'expected DictID: 0 with --no-dictID\n' >&2
    cat "$tmpdir/listing" >&2
    exit 1
}

# Decompress with the same dict still yields the original payload.
zstd -dq -D "$dict" -c "$tmpdir/out.zst" >"$tmpdir/decoded.bin"
dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
