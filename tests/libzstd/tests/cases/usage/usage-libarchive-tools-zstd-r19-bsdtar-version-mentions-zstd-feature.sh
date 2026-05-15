#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r19-bsdtar-version-mentions-zstd-feature
# @title: bsdtar --version output advertises a zstd-related feature token
# @description: Runs bsdtar --version and asserts the printed feature list mentions 'zstd' or 'libzstd' in any case, evidencing that the libarchive build linked against libzstd is the one bsdtar uses for tar.zst handling on Ubuntu 24.04.
# @timeout: 30
# @tags: usage, archive, bsdtar, zstd, version, r19
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

bsdtar --version >"$tmpdir/v.txt" 2>&1
test -s "$tmpdir/v.txt"
grep -iq 'zstd' "$tmpdir/v.txt" || {
    echo "expected bsdtar --version to mention zstd" >&2
    cat "$tmpdir/v.txt" >&2
    exit 1
}
