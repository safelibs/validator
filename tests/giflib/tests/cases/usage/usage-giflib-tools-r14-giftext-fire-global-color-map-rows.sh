#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r14-giftext-fire-global-color-map-rows
# @title: giftext -c on fire.gif lists a Global Color Map with >=8 indexed RGB rows
# @description: Runs giftext -c on fire.gif and asserts the output contains a "Global Color Map" header followed by at least 8 numeric rows. giflib 5.2.x emits each row as "<idx>:\t<r>, <g>, <b>"; older builds use bare space-separated columns. Accept either layout via a permissive index-prefixed regex.
# @timeout: 60
# @tags: usage, cli, giftext, colormap
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftext -c "$gif" >"$tmpdir/out.txt"

validator_assert_contains "$tmpdir/out.txt" 'Global Color Map'

# Match any line that starts (after optional whitespace) with one or more
# digits followed by a colon or whitespace and then at least one more digit.
# Covers giflib 5.2.x "  N:\tR, G, B" and older "  N R G B" layouts.
rows=$(grep -cE '^[[:space:]]*[0-9]+[:[:space:]]+[0-9]' "$tmpdir/out.txt" || true)
[[ "$rows" -ge 8 ]] || {
    printf 'expected >=8 colormap rows, got %s\n' "$rows" >&2
    sed -n '1,30p' "$tmpdir/out.txt" >&2
    exit 1
}
