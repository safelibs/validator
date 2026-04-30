#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giffix-corrupt-extension-byte
# @title: giffix recovers from a flipped byte after the GIF trailer
# @description: Copies treescap.gif, flips a single byte appended after the trailer to simulate corruption beyond the legitimate stream, and confirms giffix produces output that giftext can still parse, demonstrating that a stray post-trailer byte does not derail the recovery path.
# @timeout: 60
# @tags: usage, cli, giffix, repair
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

cp "$gif" "$tmpdir/dirty.gif"
# Append a single byte 0x21 (the GIF extension introducer) AFTER the trailer.
# A naive parser that does not honor the 0x3B trailer might attempt to read
# this as the start of a new extension block; giffix must still produce a
# valid GIF.
python3 -c '
import sys
with open(sys.argv[1], "ab") as fh:
    fh.write(bytes([0x21]))
' "$tmpdir/dirty.gif"

orig_size=$(wc -c <"$gif")
dirty_size=$(wc -c <"$tmpdir/dirty.gif")
[[ "$dirty_size" -eq $((orig_size + 1)) ]]

giffix "$tmpdir/dirty.gif" >"$tmpdir/fixed.gif"
file "$tmpdir/fixed.gif" | grep -q 'GIF image data'

# The repaired output must trim back to at most the original size and remain
# parseable end-to-end.
fixed_size=$(wc -c <"$tmpdir/fixed.gif")
if (( fixed_size > orig_size )); then
  printf 'expected fixed size <= %d, got %d\n' "$orig_size" "$fixed_size" >&2
  exit 1
fi

giftext "$tmpdir/fixed.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Screen Size'
grep -Eq 'Image #[0-9]+' "$tmpdir/info.txt"
