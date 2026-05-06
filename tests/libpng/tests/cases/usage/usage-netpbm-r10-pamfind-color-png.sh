#!/usr/bin/env bash
# @testcase: usage-netpbm-r10-pamfind-color-png
# @title: netpbm pamfind locates a known color in a PNG-derived PAM
# @description: Builds a PNG with a single red pixel in a known position, decodes it through pngtopam, and confirms pamfind reports the matching coordinate.
# @timeout: 180
# @tags: usage, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'P3\n3 1\n255\n0 0 0  255 0 0  0 0 0\n' >"$tmpdir/in.ppm"
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"
pngtopam "$tmpdir/in.png" | pamfind -color rgb:ff/00/00 >"$tmpdir/out.txt"

validator_assert_contains "$tmpdir/out.txt" '(0, 1)'
