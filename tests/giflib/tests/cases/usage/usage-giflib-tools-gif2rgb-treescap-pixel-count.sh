#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-treescap-pixel-count
# @title: gif2rgb treescap RGB byte count equals width*height*3
# @description: Decodes treescap.gif into a packed RGB byte stream with gif2rgb -1, parses width and height from giftext, and asserts the produced RGB output is exactly width*height*3 bytes long.
# @timeout: 60
# @tags: usage, cli, gif2rgb, geometry
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftext "$gif" >"$tmpdir/info.txt"
read -r width height < <(
  python3 - <<'PY' "$tmpdir/info.txt"
import re, sys
text = open(sys.argv[1]).read()
m = re.search(r'Width\s*=\s*(\d+)\s*,\s*Height\s*=\s*(\d+)', text)
if not m:
    sys.exit("could not parse Width/Height from giftext")
print(m.group(1), m.group(2))
PY
)
(( width > 0 && height > 0 ))

gif2rgb -1 -o "$tmpdir/treescap.rgb" "$gif"
got=$(wc -c <"$tmpdir/treescap.rgb")
expected=$(( width * height * 3 ))
if [[ "$got" -ne "$expected" ]]; then
  printf 'gif2rgb produced %d bytes, expected %d (=%dx%dx3)\n' \
    "$got" "$expected" "$width" "$height" >&2
  exit 1
fi
