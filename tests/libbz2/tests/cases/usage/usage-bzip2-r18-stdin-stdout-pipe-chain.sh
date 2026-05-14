#!/usr/bin/env bash
# @testcase: usage-bzip2-r18-stdin-stdout-pipe-chain
# @title: bzip2 -c and bunzip2 -c chain through a single shell pipeline preserving content
# @description: Generates structured text, pipes it through bzip2 -c into bunzip2 -c, captures the result, and asserts the recovered payload is identical to the original line for line and byte for byte (sha256 match) — locking in the pure-pipe streaming roundtrip without intermediate files.
# @timeout: 30
# @tags: usage, bzip2, pipeline, stdin, stdout, r18
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.txt" <<'PY'
import sys
with open(sys.argv[1], 'w') as f:
    for i in range(200):
        f.write(f"row-{i:03d}: alpha bravo charlie {i*7}\n")
PY

want_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

bzip2 -c <"$tmpdir/in.txt" | bunzip2 -c >"$tmpdir/out.txt"

got_sha=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
[[ "$got_sha" == "$want_sha" ]] || {
    printf 'roundtrip sha mismatch want=%s got=%s\n' "$want_sha" "$got_sha" >&2
    exit 1
}

lines=$(wc -l <"$tmpdir/out.txt")
[[ "$lines" -eq 200 ]] || {
    printf 'expected 200 lines, got %s\n' "$lines" >&2
    exit 1
}
