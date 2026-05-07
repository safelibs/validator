#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r14-giftext-fire-global-color-map-rows
# @title: giftext -c on fire.gif lists a Global Color Map header and >=8 numeric rows
# @description: Runs giftext -c on fire.gif and asserts the output contains a "Global Color Map" header followed by at least 8 lines that begin with a 4-integer row (index plus R G B), exercising the global color table dump.
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

# Numeric color rows look like " <idx> <r> <g> <b>". Count how many appear.
rows=$(grep -cE '^[[:space:]]*[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$tmpdir/out.txt" || true)
[[ "$rows" -ge 8 ]] || {
    printf 'expected >=8 colormap rows, got %s\n' "$rows" >&2
    sed -n '1,30p' "$tmpdir/out.txt" >&2
    exit 1
}
