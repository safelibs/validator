#!/usr/bin/env bash
# @testcase: usage-bzip2-r13-bzmore-pipe-decode
# @title: bzmore prints decoded bz2 content when piped to a non-tty
# @description: Compresses a known payload and pipes "bzmore" output through cat (so bzmore is not attached to a tty) and asserts the visible content includes the source line.
# @timeout: 60
# @tags: usage, bzmore
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'bzmore-pipe-decode-line-marker\nsecond line follows\n' >"$tmpdir/data.txt"
bzip2 "$tmpdir/data.txt"
[[ -f "$tmpdir/data.txt.bz2" ]]

bzmore "$tmpdir/data.txt.bz2" </dev/null >"$tmpdir/out.txt"
grep -F 'bzmore-pipe-decode-line-marker' "$tmpdir/out.txt" >/dev/null
grep -F 'second line follows' "$tmpdir/out.txt" >/dev/null
