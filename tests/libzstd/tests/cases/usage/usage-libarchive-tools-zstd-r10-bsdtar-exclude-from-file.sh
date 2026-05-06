#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r10-bsdtar-exclude-from-file
# @title: bsdtar zstd --exclude-from filters by pattern file
# @description: Creates a zstd archive while feeding bsdtar an --exclude-from file containing two glob patterns, then verifies the listing omits matching entries while the non-excluded member is preserved.
# @timeout: 180
# @tags: usage, archive, zstd, exclude
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'keep me\n' >"$tmpdir/in/keep.txt"
printf 'tmp data\n' >"$tmpdir/in/scratch.tmp"
printf 'log line\n' >"$tmpdir/in/run.log"

cat >"$tmpdir/excludes" <<'EOF'
*.tmp
*.log
EOF

bsdtar --zstd --exclude-from "$tmpdir/excludes" \
  -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" .

bsdtar -tf "$tmpdir/a.tar.zst" >"$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'keep.txt'

! grep -Fq 'scratch.tmp' "$tmpdir/list"
! grep -Fq 'run.log' "$tmpdir/list"
