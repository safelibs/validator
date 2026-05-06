#!/usr/bin/env bash
# @testcase: usage-netpbm-r10-pamtable-png
# @title: netpbm pamtable dumps PNG-derived PAM as a numeric table
# @description: Decodes a synthetic PNG with pngtopam and pipes it through pamtable, then verifies the resulting text grid contains the expected RGB sample values.
# @timeout: 180
# @tags: usage, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'P3\n2 1\n255\n255 0 0  0 128 64\n' >"$tmpdir/in.ppm"
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"
pngtopam "$tmpdir/in.png" | pamtable >"$tmpdir/out.txt"

validator_assert_contains "$tmpdir/out.txt" '255   0   0'
validator_assert_contains "$tmpdir/out.txt" '  0 128  64'
