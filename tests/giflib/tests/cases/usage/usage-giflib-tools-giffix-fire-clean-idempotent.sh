#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giffix-fire-clean-idempotent
# @title: giffix on already-clean fire.gif preserves giftext metadata
# @description: Pipes the already-well-formed fire.gif fixture through giffix and asserts the giftext header decoding (screen size, GIF version, and frame count from gifbuild) of the giffix output matches the source, demonstrating giffix is a no-op-equivalent on healthy inputs.
# @timeout: 60
# @tags: usage, cli, giffix, idempotent
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giffix <"$gif" >"$tmpdir/fixed.gif"
file "$tmpdir/fixed.gif" | grep -q 'GIF image data'

giftext "$gif"             >"$tmpdir/orig.txt"
giftext "$tmpdir/fixed.gif" >"$tmpdir/fixed.txt"

orig_size=$(grep -E 'Screen Size' "$tmpdir/orig.txt"  | head -n1)
fixed_size=$(grep -E 'Screen Size' "$tmpdir/fixed.txt" | head -n1)
[[ "$orig_size" == "$fixed_size" && -n "$orig_size" ]] || {
  printf 'screen size diverged: orig=%q fixed=%q\n' "$orig_size" "$fixed_size" >&2
  exit 1
}

orig_frames=$(gifbuild -d "$gif"             | grep -cE '^image # [0-9]+$' || true)
fixed_frames=$(gifbuild -d "$tmpdir/fixed.gif" | grep -cE '^image # [0-9]+$' || true)
[[ "$orig_frames" == "$fixed_frames" && "$orig_frames" -ge 2 ]] || {
  printf 'frame count diverged or not multi-frame: orig=%s fixed=%s\n' \
    "$orig_frames" "$fixed_frames" >&2
  exit 1
}
