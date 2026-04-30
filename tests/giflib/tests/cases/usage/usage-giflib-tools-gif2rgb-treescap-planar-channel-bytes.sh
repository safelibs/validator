#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-treescap-planar-channel-bytes
# @title: gif2rgb planar channel sizes equal width*height for treescap
# @description: Decodes treescap.gif into separate R/G/B planar files with gif2rgb -o, queries the screen size with giftext, and verifies each of the three channel files is exactly width*height bytes long, matching the structural invariant that planar output emits one byte per pixel per channel.
# @timeout: 60
# @tags: usage, cli, gif2rgb, planar
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

# Read screen dimensions from giftext.
giftext "$gif" >"$tmpdir/info.txt"
w=$(grep -Eo 'Width = [0-9]+' "$tmpdir/info.txt" | head -n 1 | awk '{print $3}')
h=$(grep -Eo 'Height = [0-9]+' "$tmpdir/info.txt" | head -n 1 | awk '{print $3}')
[[ "$w" =~ ^[1-9][0-9]*$ ]] || { printf 'bad width: %q\n' "$w" >&2; exit 1; }
[[ "$h" =~ ^[1-9][0-9]*$ ]] || { printf 'bad height: %q\n' "$h" >&2; exit 1; }
expected=$(( w * h ))

gif2rgb -o "$tmpdir/treescap" "$gif"

for ch in R G B; do
  validator_require_file "$tmpdir/treescap.$ch"
  bytes=$(wc -c <"$tmpdir/treescap.$ch")
  if [[ "$bytes" -ne "$expected" ]]; then
    printf 'channel %s has %d bytes, expected %d (=%dx%d)\n' \
      "$ch" "$bytes" "$expected" "$w" "$h" >&2
    exit 1
  fi
done

# All three channel files must be the same size as each other (already
# checked above against expected, but guard against off-by-one drift).
r_size=$(wc -c <"$tmpdir/treescap.R")
g_size=$(wc -c <"$tmpdir/treescap.G")
b_size=$(wc -c <"$tmpdir/treescap.B")
[[ "$r_size" -eq "$g_size" ]] && [[ "$g_size" -eq "$b_size" ]] || {
  printf 'channel sizes diverge: R=%d G=%d B=%d\n' "$r_size" "$g_size" "$b_size" >&2
  exit 1
}
