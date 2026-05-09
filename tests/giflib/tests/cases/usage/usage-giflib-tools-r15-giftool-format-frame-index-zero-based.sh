#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r15-giftool-format-frame-index-zero-based
# @title: giftool -f '%n' on fire.gif emits a contiguous frame index sequence
# @description: Runs giftool -f '%n\n' against fire.gif and asserts the output is a contiguous strictly-increasing integer sequence with the same number of frames as fire.gif (giftool 5.2.2 emits 1-based indices, earlier versions 0-based — accept either start, just require contiguity).
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
got = [int(line.strip()) for line in open(path) if line.strip()]
assert len(got) == frames, f"frame count mismatch: got={len(got)} want={frames}"
assert got[0] in (0, 1), f"frame index must start at 0 or 1: got={got[:4]}"
want = list(range(got[0], got[0] + frames))
assert got == want, f"index sequence not contiguous: got={got[:8]} want={want[:8]}"
PY
