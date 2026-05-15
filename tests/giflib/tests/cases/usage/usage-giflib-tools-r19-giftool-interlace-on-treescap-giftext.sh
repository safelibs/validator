#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r19-giftool-interlace-on-treescap-giftext
# @title: giftool -i 1 on treescap.gif flips the giftext interlace label to interlaced
# @description: Pipes treescap.gif through giftool -i 1 to enable the interlace flag (the input is non-interlaced), then runs giftext and asserts the rendered output contains the literal "Image is Interlaced." line, exercising the interlace setter through the textual report distinct from gifbuild dump-based tests.
# @timeout: 60
# @tags: usage, cli, giftool, interlace, r19
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -i 1 <"$gif" >"$tmpdir/i.gif"
file "$tmpdir/i.gif" | grep -q 'GIF image data'

giftext "$tmpdir/i.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Image is Interlaced.'
