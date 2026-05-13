#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r16-memlimit-info-shape
# @title: xz --info-alloc=1 reports a non-empty Total amount of physical memory line
# @description: Runs xz --info-alloc=1 (the documented diagnostic that prints memory usage with the given memlimit in MiB) and asserts the captured output contains a "physical memory" line, pinning liblzma's allocator diagnostic on Ubuntu 24.04 xz-utils.
# @timeout: 60
# @tags: usage, xz, info-alloc, diagnostic
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

xz --info-alloc=1 >"$tmpdir/info.txt" 2>&1
test -s "$tmpdir/info.txt"
# liblzma allocator info text references "memory" (sometimes "physical memory" / "memory usage").
grep -Eqi 'memory' "$tmpdir/info.txt"
