#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r17-xz-format-raw-without-filters-fails
# @title: xz --format=raw without a filter chain rejects the request
# @description: Invokes xz --format=raw with no --filters chain and asserts a non-zero exit, locking in that raw format requires an explicit filter specification on Ubuntu 24.04 xz-utils.
# @timeout: 60
# @tags: usage, xz, format, raw, negative
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r17 raw without filters\n' >"$tmpdir/in.txt"

set +e
xz --format=raw -c "$tmpdir/in.txt" >"$tmpdir/out.raw" 2>"$tmpdir/err.log"
rc=$?
set -e

[[ "$rc" -ne 0 ]] || {
  printf 'expected non-zero exit; xz accepted raw without filters\n' >&2
  exit 1
}
