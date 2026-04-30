#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giffix-trailing-junk
# @title: giffix tolerates trailing garbage
# @description: Appends 16 bytes of garbage after the GIF trailer and confirms giffix produces output that giftext still parses, demonstrating the recovery path is not derailed by stray trailing bytes.
# @timeout: 60
# @tags: usage, cli, giffix, repair
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

cp "$gif" "$tmpdir/with-junk.gif"
python3 -c '
import sys
with open(sys.argv[1], "ab") as fh:
    fh.write(b"\x00" * 16)
' "$tmpdir/with-junk.gif"

orig_size=$(wc -c <"$gif")
junked_size=$(wc -c <"$tmpdir/with-junk.gif")
[[ "$junked_size" -eq $((orig_size + 16)) ]]

giffix "$tmpdir/with-junk.gif" >"$tmpdir/fixed.gif"
file "$tmpdir/fixed.gif" | grep -q 'GIF image data'

giftext "$tmpdir/fixed.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Screen Size'
grep -Eq 'Image #[0-9]+' "$tmpdir/info.txt"
