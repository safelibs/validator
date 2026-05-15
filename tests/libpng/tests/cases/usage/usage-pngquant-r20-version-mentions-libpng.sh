#!/usr/bin/env bash
# @testcase: usage-pngquant-r20-version-mentions-libpng
# @title: pngquant --help banner reports libpng as the linked decode library
# @description: Runs pngquant --help and asserts the first lines of output contain the literal substring "libpng", pinning that the pngquant CLI advertises libpng as its linked PNG codec dependency on Ubuntu 24.04.
# @timeout: 30
# @tags: usage, png, pngquant, version, libpng, r20
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

pngquant --help >"$tmpdir/help.txt" 2>&1 || true
validator_require_file "$tmpdir/help.txt"
grep -Fq 'libpng' "$tmpdir/help.txt"
