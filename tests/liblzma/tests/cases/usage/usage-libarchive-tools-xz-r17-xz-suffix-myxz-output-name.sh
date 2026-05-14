#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r17-xz-suffix-myxz-output-name
# @title: xz -S .myxz writes the compressed file with the requested suffix
# @description: Runs xz -S .myxz on a payload file and asserts the resulting file is named "<input>.myxz" rather than the default ".xz", pinning the --suffix override behavior.
# @timeout: 60
# @tags: usage, xz, suffix
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r17 custom suffix payload\n' >"$tmpdir/data.txt"
xz -S .myxz "$tmpdir/data.txt"

test -f "$tmpdir/data.txt.myxz" \
  || { printf 'expected suffix .myxz, missing\n' >&2; exit 1; }
test ! -f "$tmpdir/data.txt.xz" \
  || { printf 'unexpected default .xz suffix file\n' >&2; exit 1; }
