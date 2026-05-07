#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r13-giftext-fire-version-line
# @title: giftext on fire.gif emits a Screen Size line with positive dimensions
# @description: Runs plain giftext on fire.gif and asserts the screen-descriptor section names a "Screen Size" line whose width and height parse as positive integers, exercising the giftext header-section formatter.
# @timeout: 60
# @tags: usage, cli, giftext, screen
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftext "$gif" >"$tmpdir/text.out"

# Screen Size header in giftext appears as "Screen Size - Width = N, Height = N".
line=$(grep -E 'Screen Size' "$tmpdir/text.out" | head -n 1 || true)
if [[ -z "$line" ]]; then
    printf 'no Screen Size line in giftext output\n' >&2
    sed -n '1,20p' "$tmpdir/text.out" >&2
    exit 1
fi

# Cross-check the parsed width and height are positive ints.
w=$(printf '%s\n' "$line" | sed -n 's/.*Width = \([0-9]\+\).*/\1/p')
h=$(printf '%s\n' "$line" | sed -n 's/.*Height = \([0-9]\+\).*/\1/p')
[[ -n "$w" && -n "$h" ]] || {
    printf 'could not parse width/height from: %s\n' "$line" >&2
    exit 1
}
[[ "$w" -gt 0 && "$h" -gt 0 ]]

# And the parsed pair must agree with giftool -f '%s\n'.
giftool_screen=$(giftool -f '%s\n' <"$gif" | head -n 1)
[[ "$giftool_screen" == "$w,$h" ]] || {
    printf 'mismatch: giftext=%sx%s vs giftool=%s\n' "$w" "$h" "$giftool_screen" >&2
    exit 1
}
