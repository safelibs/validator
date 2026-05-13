#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r16-bsdtar-ustar-magic-bytes
# @title: bsdtar --format=ustar through xz round-trip writes a ustar magic header
# @description: Builds a tar.xz with bsdtar --format=ustar -cJf, decompresses with xz -d, and asserts the resulting tar's first 512-byte header contains the literal "ustar" magic at offset 257 — confirming the format flag is honoured on a tar.xz round trip.
# @timeout: 120
# @tags: usage, bsdtar, xz, ustar
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'hello\n' >"$tmpdir/src/f.txt"

(cd "$tmpdir/src" && bsdtar --format=ustar -cJf "$tmpdir/out.tar.xz" f.txt)
xz -d -c "$tmpdir/out.tar.xz" >"$tmpdir/out.tar"

python3 - "$tmpdir/out.tar" <<'PY'
import sys
data = open(sys.argv[1], 'rb').read()
assert len(data) >= 512
magic = data[257:262]
assert magic == b'ustar', f'expected ustar magic at offset 257, got {magic!r}'
PY
