#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifclrmp-fire-image-select
# @title: gifclrmp -s dumps the global colormap of fire.gif
# @description: Runs gifclrmp -s on the multi-frame fire.gif to dump its global colormap as text and verifies the dump contains at least two palette rows whose first row parses as "<index> <r> <g> <b>" with r,g,b in [0,255], confirming gifclrmp produces a well-formed palette dump for a multi-frame GIF.
# @timeout: 60
# @tags: usage, cli, gifclrmp, palette
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

gifclrmp -s "$gif" >"$tmpdir/cmap.txt"

rows=$(wc -l <"$tmpdir/cmap.txt")
(( rows >= 2 )) || {
  printf 'expected at least 2 palette rows, got %d\n' "$rows" >&2
  exit 1
}

python3 - "$tmpdir/cmap.txt" <<'PY'
import sys
path = sys.argv[1]
with open(path) as fh:
    for raw in fh:
        parts = raw.split()
        if not parts or not parts[0].isdigit():
            continue
        if len(parts) < 4:
            sys.exit(f"row too short: {raw!r}")
        idx, r, g, b = parts[:4]
        for n in (idx, r, g, b):
            if not n.isdigit():
                sys.exit(f"non-numeric token in {raw!r}")
        for n in (r, g, b):
            v = int(n)
            if v < 0 or v > 255:
                sys.exit(f"channel out of range in {raw!r}")
        break
    else:
        sys.exit(f"no palette rows in {path}")
PY
