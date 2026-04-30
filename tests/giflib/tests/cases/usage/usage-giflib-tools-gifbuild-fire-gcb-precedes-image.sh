#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-fire-gcb-precedes-image
# @title: gifbuild dump pairs a graphics control with each animated frame
# @description: Dumps the animated fire.gif with gifbuild -d, scans the textual record stream, and asserts that every "image # N" header has a "graphics control" block emitted ahead of it, confirming gifbuild reports the per-frame timing extension on a real animation rather than just the global header.
# @timeout: 60
# @tags: usage, cli, gifbuild, animation
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/dump.txt"

image_headers=$(grep -cE '^image # [0-9]+$' "$tmpdir/dump.txt" || true)
gcb_blocks=$(grep -c '^graphics control$' "$tmpdir/dump.txt" || true)

(( image_headers >= 5 )) || {
  printf 'expected fire.gif to be animated, only %d image headers\n' "$image_headers" >&2
  exit 1
}
if (( gcb_blocks < image_headers )); then
  printf 'expected one graphics control per image header; got %d gcb vs %d images\n' \
    "$gcb_blocks" "$image_headers" >&2
  exit 1
fi

# Walk line-by-line and ensure no "image # N" is reached without a "graphics
# control" block having been seen since the previous image (i.e. each frame
# is preceded by its GCE in the dump order).
python3 - "$tmpdir/dump.txt" <<'PY'
import re, sys
seen_gcb_since_last_image = False
saw_first = False
with open(sys.argv[1]) as fh:
    for line in fh:
        line = line.rstrip("\n")
        if line == "graphics control":
            seen_gcb_since_last_image = True
        elif re.match(r"^image # [0-9]+$", line):
            if not seen_gcb_since_last_image:
                sys.stderr.write(f"image header without preceding GCE: {line}\n")
                sys.exit(1)
            saw_first = True
            seen_gcb_since_last_image = False
if not saw_first:
    sys.stderr.write("no image headers parsed from dump\n")
    sys.exit(1)
PY
