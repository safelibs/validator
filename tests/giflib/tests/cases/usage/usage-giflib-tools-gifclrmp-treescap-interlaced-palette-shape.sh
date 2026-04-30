#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifclrmp-treescap-interlaced-palette-shape
# @title: gifclrmp -s on treescap-interlaced emits a power-of-two palette
# @description: Dumps the global color map of the treescap-interlaced.gif fixture with gifclrmp -s, asserts the row count is one of the GIF-permitted palette sizes (2, 4, 8, 16, 32, 64, 128 or 256), and verifies every dump line matches the expected "index R G B" four-token shape with each channel a 0-255 byte.
# @timeout: 60
# @tags: usage, cli, gifclrmp, colormap, interlace
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap-interlaced.gif"
validator_require_file "$gif"

gifclrmp -s "$gif" >"$tmpdir/cmap.txt"
rows=$(wc -l <"$tmpdir/cmap.txt")

case "$rows" in
  2|4|8|16|32|64|128|256) ;;
  *)
    printf 'unexpected palette row count: %d (must be a power of two between 2 and 256)\n' "$rows" >&2
    sed -n '1,5p' "$tmpdir/cmap.txt" >&2
    exit 1
    ;;
esac

# Every row must be "index R G B" with 0 <= channel <= 255.
python3 - <<'PY' "$tmpdir/cmap.txt"
import sys
seen_idx = []
with open(sys.argv[1]) as fh:
    for lineno, raw in enumerate(fh, 1):
        toks = raw.split()
        if len(toks) != 4:
            sys.exit(f"line {lineno}: expected 4 tokens, got {toks}")
        try:
            idx, r, g, b = (int(t) for t in toks)
        except ValueError:
            sys.exit(f"line {lineno}: non-integer token in {toks}")
        for name, val in (("idx", idx), ("r", r), ("g", g), ("b", b)):
            if not (0 <= val <= 255):
                sys.exit(f"line {lineno}: {name}={val} outside 0..255")
        seen_idx.append(idx)

# Indices must start at 0 and be strictly increasing.
if seen_idx and seen_idx[0] != 0:
    sys.exit(f"first index must be 0, got {seen_idx[0]}")
if seen_idx != sorted(set(seen_idx)):
    sys.exit(f"indices not strictly increasing: {seen_idx[:8]}")
PY
