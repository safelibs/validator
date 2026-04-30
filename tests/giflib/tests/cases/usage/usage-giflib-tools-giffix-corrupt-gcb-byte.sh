#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giffix-corrupt-gcb-byte
# @title: giffix strips trailing junk bytes after a GIF trailer
# @description: Appends 96 zero bytes after the canonical 0x3B trailer of a copy of treescap.gif to simulate trailing garbage, runs giffix on the dirty stream, and verifies the recovered output is recognized as GIF data, ends with the canonical 0x3B trailer byte, and parses through giftext.
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

# Append 96 zero bytes after the canonical 0x3B trailer to simulate trailing
# garbage. giffix must produce a clean stream that ends at the real trailer.
python3 -c '
import sys
path = sys.argv[1]
with open(path, "r+b") as fh:
    fh.seek(-1, 2)
    last = fh.read(1)
    if last != b"\x3B":
        sys.exit(f"fixture does not end with 0x3B trailer, got {last!r}")
    fh.seek(0, 2)
    fh.write(b"\x00" * 96)
' "$tmpdir/dirty.gif"

[[ "$(wc -c <"$tmpdir/dirty.gif")" -eq "$(( orig_size + 96 ))" ]] || {
  printf 'expected dirty fixture to be 96 bytes longer than the source\n' >&2
  exit 1
}

giffix "$tmpdir/dirty.gif" >"$tmpdir/fixed.gif"
file "$tmpdir/fixed.gif" | grep -q 'GIF image data'

# Recovered stream must end with the canonical 0x3B trailer byte.
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

giftext "$tmpdir/fixed.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Screen Size'
grep -Eq 'Image #[0-9]+' "$tmpdir/info.txt"
