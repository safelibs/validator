#!/usr/bin/env bash
# @testcase: usage-bzip2-r17-stdin-pipe-roundtrip-sha256
# @title: bzip2 -c stdin pipe roundtrip preserves SHA-256 with no temp file
# @description: Pipes a payload into bzip2 -c and immediately into bzip2 -dc, capturing the recovered bytes on stdout, and asserts the SHA-256 of the recovered stream equals the SHA-256 of the original input — locking in a purely streaming roundtrip free of intermediate archive files.
# @timeout: 60
# @tags: usage, bzip2, stdin, pipe, sha256
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "
import sys
for i in range(500):
    sys.stdout.write(f'r17 stream {i} payload line for bzip2 -c pipe roundtrip\n')
" >"$tmpdir/payload.txt"

want=$(sha256sum "$tmpdir/payload.txt" | awk '{print $1}')
got=$(bzip2 -c <"$tmpdir/payload.txt" | bzip2 -dc | sha256sum | awk '{print $1}')

[[ "$want" == "$got" ]] || {
    printf 'sha256 mismatch: want=%s got=%s\n' "$want" "$got" >&2
    exit 1
}
