#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r11-giftext-pixmap-treescap-offset-prefix
# @title: giftext -p emits hex-offset prefixed pixmap rows for treescap
# @description: Runs giftext -p on the treescap fixture and verifies the pixmap section contains at least 40 lines whose left margin is a five-hex-digit offset followed by a colon, matching the per-row stride formatting.
# @timeout: 60
# @tags: usage, cli, giftext, pixmap
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftext -p "$gif" >"$tmpdir/pixmap.txt"

rows=$(grep -cE '^[0-9a-f]{5}:' "$tmpdir/pixmap.txt")
if [[ "$rows" -lt 40 ]]; then
    printf 'expected at least 40 hex-offset rows, got %s\n' "$rows" >&2
    sed -n '1,5p' "$tmpdir/pixmap.txt" >&2
    exit 1
fi
