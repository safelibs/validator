#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r15-giftool-format-frame-index-zero-based
# @title: giftool -f '%n' on fire.gif emits a zero-based contiguous frame index sequence
# @description: Runs giftool -f '%n\n' against fire.gif and asserts the output is a zero-based, strictly contiguous integer sequence (0, 1, 2, ..., N-1) by comparing against a Python-generated reference, exercising the per-frame index emission contract.
# @timeout: 60
# @tags: usage, cli, giftool, format
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -f '%n\n' <"$gif" >"$tmpdir/n.txt"
[[ -s "$tmpdir/n.txt" ]]

frames=$(wc -l <"$tmpdir/n.txt")
[[ "$frames" -ge 2 ]]

python3 - "$tmpdir/n.txt" "$frames" <<'PY'
import sys
path, frames = sys.argv[1], int(sys.argv[2])
got = [line.strip() for line in open(path) if line.strip()]
want = [str(i) for i in range(frames)]
assert got == want, f"index sequence mismatch: got={got[:8]} want={want[:8]}"
PY
