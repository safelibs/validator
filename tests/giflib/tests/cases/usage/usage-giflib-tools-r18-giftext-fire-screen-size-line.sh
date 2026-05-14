#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r18-giftext-fire-screen-size-line
# @title: giftext on fire.gif emits a Screen Size header line
# @description: Runs giftext on fire.gif and asserts the report contains the literal substring "Screen Size" (case-insensitive), exercising the global screen descriptor section emission distinct from the color map section.
# @timeout: 60
# @tags: usage, cli, giftext, screen-size, r18
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftext "$gif" >"$tmpdir/info.txt"
grep -qi 'Screen Size' "$tmpdir/info.txt" || {
    printf 'expected Screen Size line in giftext output:\n' >&2
    sed -n '1,80p' "$tmpdir/info.txt" >&2
    exit 1
}
