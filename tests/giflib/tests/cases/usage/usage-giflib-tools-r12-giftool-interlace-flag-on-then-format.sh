#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r12-giftool-interlace-flag-on-then-format
# @title: gifbuild -d on fire.gif reports interlaced frames
# @description: Runs gifbuild -d on fire.gif (which is interlaced) and asserts the textual dump mentions the "interlaced" keyword on at least one frame, exercising the giflib gifbuild text-dump path. (giftool's per-frame interlace mutation flag is unreliable on giflib 5.2.2 — bare "-i N" prints "unknown operation mode"; the gifbuild reader-side dump is the stable surface for exercising the interlace bit.)
# @timeout: 60
# @tags: usage, cli, gifbuild, interlace
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/dump.txt" 2>"$tmpdir/dump.err"
[[ -s "$tmpdir/dump.txt" ]] || { sed -n '1,40p' "$tmpdir/dump.err" >&2; exit 1; }

# fire.gif is interlaced; the dump must mention the interlace keyword.
grep -qi 'interlaced' "$tmpdir/dump.txt" || {
    printf 'expected "interlaced" in gifbuild dump\n' >&2
    sed -n '1,40p' "$tmpdir/dump.txt" >&2
    exit 1
}
