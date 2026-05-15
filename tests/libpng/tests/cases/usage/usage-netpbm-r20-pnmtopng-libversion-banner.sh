#!/usr/bin/env bash
# @testcase: usage-netpbm-r20-pnmtopng-libversion-banner
# @title: netpbm pnmtopng -libversion mentions libpng in the banner output
# @description: Runs pnmtopng -libversion and asserts the printed banner contains the substring "libpng", pinning that the netpbm encoder reports its underlying libpng dependency on Ubuntu 24.04.
# @timeout: 30
# @tags: usage, png, netpbm, pnmtopng, libversion, r20
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

pnmtopng -libversion >"$tmpdir/banner.txt" 2>&1
validator_require_file "$tmpdir/banner.txt"
grep -Fq 'libpng' "$tmpdir/banner.txt"
