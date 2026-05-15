#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r19-giftext-fire-disposal-mode-line
# @title: giftext on fire.gif emits per-frame "Disposal Mode:" lines
# @description: Runs giftext on fire.gif and asserts the rendered report contains at least one line starting with the literal "Disposal Mode:", exercising the graphics-control-extension disposal-field emission on the multi-frame animation fixture distinct from screen-size and color-map section tests.
# @timeout: 60
# @tags: usage, cli, giftext, disposal, r19
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftext "$gif" >"$tmpdir/info.txt"
count=$(grep -c 'Disposal Mode:' "$tmpdir/info.txt" || true)
(( count > 0 )) || {
    printf 'expected at least one Disposal Mode line, got %s\n' "$count" >&2
    sed -n '1,80p' "$tmpdir/info.txt" >&2
    exit 1
}
