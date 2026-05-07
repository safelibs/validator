#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r13-gifbuild-treescap-image-line-count-matches-frames
# @title: gifbuild -d on treescap emits one image directive per frame
# @description: Runs gifbuild -d on treescap.gif and counts top-level "image" directives in the dump, asserting the count equals the per-frame count reported by giftool -f '%n\n', confirming the dump and tool agree on frame count.
# @timeout: 60
# @tags: usage, cli, gifbuild, dump
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/dump.txt"
giftool -f '%n\n' <"$gif" >"$tmpdir/n.txt"

# Image directives in gifbuild's dump appear as "image # N" headers per frame.
img_lines=$(grep -cE '^image # [0-9]+$' "$tmpdir/dump.txt" || true)
frames=$(wc -l <"$tmpdir/n.txt")

[[ "$frames" -ge 1 ]]
[[ "$img_lines" -eq "$frames" ]] || {
    printf 'gifbuild image lines=%s != giftool frames=%s\n' "$img_lines" "$frames" >&2
    sed -n '1,40p' "$tmpdir/dump.txt" >&2
    exit 1
}
