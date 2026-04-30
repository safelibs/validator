#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-fire-extension-lines
# @title: gifbuild fire extension records
# @description: Dumps the animated fire.gif with gifbuild -d and verifies the textual description contains the multiple per-frame image-block headers emitted for an animated GIF.
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

# fire.gif is a multi-frame animation; gifbuild emits one `image # N`
# header per frame and one `graphics control` block (with `disposal mode`,
# `delay`, and `transparent index` sub-records) per frame. Require several
# of each so we are exercising the animated-GIF dump path rather than just
# the global header.
image_headers=$(grep -cE '^image # [0-9]+$' "$tmpdir/dump.txt" || true)
if (( image_headers < 5 )); then
  printf 'expected >=5 "image # N" headers in gifbuild dump, got %d\n' "$image_headers" >&2
  sed -n '1,40p' "$tmpdir/dump.txt" >&2
  exit 1
fi
gcb_count=$(grep -c '^graphics control$' "$tmpdir/dump.txt" || true)
if (( gcb_count < 5 )); then
  printf 'expected >=5 "graphics control" blocks in gifbuild dump, got %d\n' "$gcb_count" >&2
  exit 1
fi
disposal_count=$(grep -cE '^[[:space:]]+disposal mode [0-9]+' "$tmpdir/dump.txt" || true)
if (( disposal_count < 5 )); then
  printf 'expected >=5 "disposal mode" lines in gifbuild dump, got %d\n' "$disposal_count" >&2
  exit 1
fi
