#!/usr/bin/env bash
# @testcase: usage-bzip2-r19-decompress-stdin-block-1
# @title: bzip2 -d via stdin recovers a payload compressed at block size 1
# @description: Compresses a 16 KiB payload of repeating mixed-case text using bzip2 -1 to stdout, pipes the archive into bzip2 -dc, and asserts the recovered bytes are byte-identical (sha256 match) to the source - locking in stdin decompression of small-block archives.
# @timeout: 60
# @tags: usage, bzip2, stdin, block-size, r19
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.txt" <<'PY'
import sys
with open(sys.argv[1], 'w') as f:
    for i in range(512):
        f.write(f"ROW-{i:03d} The Quick Brown fox jumps Over the lazy DOG\n")
PY

want_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

bzip2 -1 -c <"$tmpdir/in.txt" >"$tmpdir/in.bz2"
bzip2 -dc <"$tmpdir/in.bz2" >"$tmpdir/out.txt"

got_sha=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
[[ "$got_sha" == "$want_sha" ]] || {
    printf 'sha mismatch: want=%s got=%s\n' "$want_sha" "$got_sha" >&2
    exit 1
}
