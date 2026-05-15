#!/usr/bin/env bash
# @testcase: usage-vips-r19-jpegsave-q1-vs-q95-smaller
# @title: vips jpegsave --Q 1 produces a strictly smaller file than --Q 95
# @description: Builds a 48x32 RGB PPM with deterministic pseudo-random bytes, saves it as JPEG via vips jpegsave at --Q 1 and --Q 95 respectively, and asserts the --Q 1 output file is strictly smaller in bytes than the --Q 95 output, exercising libjpeg-turbo's quantisation-table scaling through vips jpegsave's --Q control.
# @timeout: 180
# @tags: usage, vips, jpeg, quality, size-monotonic, r19
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

W=48; H=32
{
  printf 'P6\n%d %d\n255\n' "$W" "$H"
  head -c $((W * H * 3)) /dev/urandom
} >"$tmpdir/in.ppm"

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/low.jpg" --Q 1
vips jpegsave "$tmpdir/in.ppm" "$tmpdir/high.jpg" --Q 95

s_low=$(wc -c <"$tmpdir/low.jpg")
s_high=$(wc -c <"$tmpdir/high.jpg")
if [[ "$s_low" -ge "$s_high" ]]; then
  printf 'expected Q=1 (%s) < Q=95 (%s)\n' "$s_low" "$s_high" >&2
  exit 1
fi
