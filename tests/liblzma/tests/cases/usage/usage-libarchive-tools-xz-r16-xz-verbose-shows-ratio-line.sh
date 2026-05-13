#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r16-xz-verbose-shows-ratio-line
# @title: xz --verbose stderr advertises a compression ratio line
# @description: Runs xz --verbose -c on a small payload and asserts the captured stderr contains the literal "ratio" token (matches "Compression ratio:" or "ratio"), pinning the verbose-mode diagnostic without asserting an exact numeric ratio.
# @timeout: 60
# @tags: usage, xz, verbose, ratio
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a payload with repetitive content so xz produces a meaningful ratio.
python3 - "$tmpdir/in.txt" <<'PY'
import sys
open(sys.argv[1], 'w').write(('hello world ' * 200) + '\n')
PY

xz --verbose -c "$tmpdir/in.txt" >"$tmpdir/out.xz" 2>"$tmpdir/err.txt"
test -s "$tmpdir/out.xz"
test -s "$tmpdir/err.txt"
grep -Eqi 'ratio' "$tmpdir/err.txt"
