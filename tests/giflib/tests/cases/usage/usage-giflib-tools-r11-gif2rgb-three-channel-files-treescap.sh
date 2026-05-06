#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r11-gif2rgb-three-channel-files-treescap
# @title: gif2rgb without -1 emits separate R/G/B files for treescap
# @description: Runs gif2rgb -o on the treescap fixture (40x40) and verifies it writes three sibling channel files <out>.R, <out>.G, <out>.B, each exactly 1600 bytes (one byte per pixel per channel).
# @timeout: 60
# @tags: usage, cli, gif2rgb, channels
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gif2rgb -o "$tmpdir/chan" "$gif"

for ch in R G B; do
    f="$tmpdir/chan.$ch"
    validator_require_file "$f"
    sz=$(stat -c '%s' "$f")
    if [[ "$sz" -ne 1600 ]]; then
        printf '%s expected 1600 bytes, got %s\n' "$f" "$sz" >&2
        exit 1
    fi
done
