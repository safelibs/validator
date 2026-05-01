#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-fire-screen-then-format-shows-new-size
# @title: giftool -s pipeline followed by giftool -f reports the rewritten screen
# @description: Resizes fire.gif logical screen to 200,100 with giftool -s, pipes the result into a second giftool -f '%s' invocation, and asserts every emitted line reports the new screen-size token 200,100, confirming -f reads the just-written screen descriptor across a pipe boundary.
# @timeout: 60
# @tags: usage, cli, giftool, pipeline, format
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -s 200,100 <"$gif" >"$tmpdir/resized.gif"
file "$tmpdir/resized.gif" | grep -q 'GIF image data'

giftool -f '%s\n' <"$tmpdir/resized.gif" >"$tmpdir/sizes.txt"
[[ -s "$tmpdir/sizes.txt" ]] || {
  printf 'giftool -f produced no output on resized fire.gif\n' >&2
  exit 1
}

# Every emitted line must be exactly the new screen-size token. If even one
# line disagrees, the screen descriptor was not consistently rewritten.
non_matching=$(grep -vc '^200,100$' "$tmpdir/sizes.txt" || true)
if [[ "$non_matching" != "0" ]]; then
  printf 'expected every line to be "200,100"; %s diverged\n' "$non_matching" >&2
  sed -n '1,5p' "$tmpdir/sizes.txt" >&2
  exit 1
fi
