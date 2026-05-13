#!/usr/bin/env bash
# @testcase: usage-bzip2-r16-bzcat-stdin-pipe
# @title: bzcat decodes a bz2 stream from stdin via pipeline
# @description: Streams a bzip2-compressed payload into bzcat over a pipeline and asserts the decoded stdout matches the original input byte-for-byte, locking in the pure-stdin pipe path without temporary archive files on disk.
# @timeout: 60
# @tags: usage, bzcat, stdin, pipe
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r16 bzcat-stdin-pipe alpha\nbravo\ncharlie\n' >"$tmpdir/payload.txt"

bzip2 -c "$tmpdir/payload.txt" | bzcat >"$tmpdir/decoded.txt"

diff -q "$tmpdir/payload.txt" "$tmpdir/decoded.txt"
