#!/usr/bin/env bash
# @testcase: usage-pngquant-r21-help-mentions-libpng-build
# @title: pngquant --help banner reports the libpng version it was compiled against
# @description: Runs pngquant --help and asserts the first banner line mentions "libpng" alongside a numeric version, pinning the libpng build-time dependency advertised in the pngquant CLI banner.
# @timeout: 30
# @tags: usage, png, pngquant, help, libpng-banner, r21
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

pngquant --help >"$tmpdir/help.txt" 2>&1 || true
validator_require_file "$tmpdir/help.txt"
grep -Eq 'libpng[[:space:]][0-9]+\.[0-9]+' "$tmpdir/help.txt"
