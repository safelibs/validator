#!/usr/bin/env bash
# @testcase: usage-bzip2-r20-bzcat-empty-stream-yields-zero-bytes
# @title: bzcat on an archive of an empty file emits zero bytes to stdout
# @description: Compresses a zero-byte file with bzip2, then runs bzcat on the resulting archive and asserts the captured stdout is exactly 0 bytes long via wc -c, exercising the zero-payload case of bzcat distinct from prior empty-archive tests that asserted via diff.
# @timeout: 30
# @tags: usage, bzcat, empty, r20
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

: >"$tmpdir/empty.txt"
bzip2 "$tmpdir/empty.txt"
[[ -f "$tmpdir/empty.txt.bz2" ]] || { printf 'archive not created\n' >&2; exit 1; }

bzcat "$tmpdir/empty.txt.bz2" >"$tmpdir/out.bin"
got=$(stat -c '%s' "$tmpdir/out.bin")
[[ "$got" == "0" ]] || { printf 'expected 0 bytes, got %s\n' "$got" >&2; exit 1; }
