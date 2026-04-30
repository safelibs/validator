#!/usr/bin/env bash
# @testcase: usage-bzmore-shows-first-lines
# @title: bzmore shows first lines
# @description: Runs bzmore with cat as the pager on a multi-line compressed file and verifies the first three plaintext lines appear in order at the start of the output.
# @timeout: 180
# @tags: usage, bzip2, pager
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzmore-shows-first-lines"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/plain.txt" <<'PY'
import sys
path = sys.argv[1]
with open(path, "w") as f:
    for i in range(1, 11):
        f.write(f"bzmore-line-{i}\n")
PY

bzip2 -k "$tmpdir/plain.txt"
PAGER=cat bzmore "$tmpdir/plain.txt.bz2" >"$tmpdir/out"

# Pull out only payload lines (bzmore may emit a header banner).
grep -E '^bzmore-line-[0-9]+$' "$tmpdir/out" >"$tmpdir/lines"
head -3 "$tmpdir/lines" >"$tmpdir/first3"

printf 'bzmore-line-1\nbzmore-line-2\nbzmore-line-3\n' >"$tmpdir/expected"
cmp "$tmpdir/first3" "$tmpdir/expected"
