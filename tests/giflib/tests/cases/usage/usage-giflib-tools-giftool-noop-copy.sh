#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-noop-copy
# @title: giftool no-op preserves GIF screen dimensions
# @description: Pipes a fixture through giftool with no transforms and confirms the copy is a valid GIF whose screen size matches the source as reported by giftext.
# @timeout: 60
# @tags: usage, cli, giftool
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool <"$gif" >"$tmpdir/copy.gif"
file "$tmpdir/copy.gif" | grep -q 'GIF image data'

# Both source and copy must report the same logical screen width/height in
# the giftext "Screen Size" record. This is a stable structural invariant of
# a noop giftool round-trip without depending on byte-exact metadata.
giftext "$gif"            >"$tmpdir/orig.txt" 2>&1 || true
giftext "$tmpdir/copy.gif" >"$tmpdir/copy.txt" 2>&1 || true

orig_size=$(grep -E 'Screen[[:space:]]+Size' "$tmpdir/orig.txt" | head -n 1)
copy_size=$(grep -E 'Screen[[:space:]]+Size' "$tmpdir/copy.txt" | head -n 1)

[[ -n "$orig_size" ]] || { printf 'no Screen Size in orig giftext\n' >&2; sed -n '1,40p' "$tmpdir/orig.txt" >&2; exit 1; }
[[ "$orig_size" == "$copy_size" ]] || {
  printf 'screen size mismatch: orig=%q copy=%q\n' "$orig_size" "$copy_size" >&2
  exit 1
}
