#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giffix-zeroed-trailer
# @title: giffix removes zero-bytes appended after the GIF trailer
# @description: Copies treescap.gif, appends 64 zero bytes after the canonical 0x3B trailer so the stream has trailing garbage past the terminator, runs giffix on the dirty file, and verifies the repaired output is recognized as GIF data, ends with the canonical 0x3B trailer, and parses through giftext.
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
orig_size=$(wc -c <"$gif")

# Append 64 zero bytes after the canonical 0x3B trailer so the file has
# trailing garbage past the GIF terminator. giffix should ignore the noise
# and emit a clean stream that ends at the real trailer.
python3 -c '
import sys
path = sys.argv[1]
with open(path, "r+b") as fh:
    fh.seek(-1, 2)
    last = fh.read(1)
    if last != b"\x3B":
        sys.exit(f"expected fixture to end with 0x3B trailer, got {last!r}")
    fh.seek(0, 2)
    fh.write(b"\x00" * 64)
' "$tmpdir/dirty.gif"

# Size must be exactly 64 bytes larger (the appended zero padding).
[[ "$(wc -c <"$tmpdir/dirty.gif")" -eq "$((orig_size + 64))" ]]

giffix "$tmpdir/dirty.gif" >"$tmpdir/fixed.gif"
file "$tmpdir/fixed.gif" | grep -q 'GIF image data'

# The repaired stream must end with the canonical 0x3B trailer byte.
last_byte=$(python3 -c '
import sys
with open(sys.argv[1], "rb") as fh:
    fh.seek(-1, 2)
    sys.stdout.write("%02x" % fh.read(1)[0])
' "$tmpdir/fixed.gif")
[[ "$last_byte" == "3b" ]] || {
  printf 'expected fixed file to end with 0x3B, got 0x%s\n' "$last_byte" >&2
  exit 1
}

# And the repaired stream must remain parseable end-to-end.
giftext "$tmpdir/fixed.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Screen Size'
grep -Eq 'Image #[0-9]+' "$tmpdir/info.txt"
