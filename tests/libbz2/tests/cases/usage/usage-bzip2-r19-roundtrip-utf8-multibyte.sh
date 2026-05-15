#!/usr/bin/env bash
# @testcase: usage-bzip2-r19-roundtrip-utf8-multibyte
# @title: bzip2 round-trips UTF-8 multibyte sequences byte-for-byte
# @description: Writes a text containing multibyte UTF-8 sequences (Greek, CJK, emoji-range BMP), compresses with bzip2 then decompresses to a new file, and asserts the recovered bytes match the source by sha256 - locking in 8-bit-clean handling of multibyte payloads.
# @timeout: 30
# @tags: usage, bzip2, utf8, fidelity, r19
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.txt" <<'PY'
import sys
content = "Greek: αβγδε\nCJK: 中文测试\nSymbols: ☃★♥\nLatin: café naïve résumé\n"
with open(sys.argv[1], 'w', encoding='utf-8') as f:
    f.write(content)
PY

want_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')
bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.bz2"
bzip2 -dc "$tmpdir/in.bz2" >"$tmpdir/out.txt"

got_sha=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
[[ "$got_sha" == "$want_sha" ]] || {
    printf 'sha mismatch: want=%s got=%s\n' "$want_sha" "$got_sha" >&2
    exit 1
}
