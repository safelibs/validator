#!/usr/bin/env bash
# @testcase: usage-netpbm-r18-pngtopam-fixture-pamfile-dims
# @title: netpbm pngtopam on a PngSuite 32x32 fixture reports "32 by 32" via pamfile
# @description: Decodes the basn2c08.png PngSuite fixture with pngtopam and asserts pamfile reports "32 by 32" — pinning libpng-mediated dimension fidelity on a real PngSuite sample.
# @timeout: 120
# @tags: usage, png, netpbm, pngtopam, fixture, r18
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cp /validator/tests/libpng/tests/fixtures/samples/contrib/pngsuite/basn2c08.png "$tmpdir/in.png"

pngtopam "$tmpdir/in.png" >"$tmpdir/out.pam"
pamfile "$tmpdir/out.pam" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" '32 by 32'
