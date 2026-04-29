#!/usr/bin/env bash
# @testcase: usage-tar-gzip-archive
# @title: tar gzip archive
# @description: Creates and extracts a gzip-compressed tar archive with libc-backed tools.
# @timeout: 180
# @tags: usage, archive
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-tar-gzip-archive"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src" "$tmpdir/outdir"
printf 'tar gzip payload\n' >"$tmpdir/src/file.txt"
tar -C "$tmpdir/src" -czf "$tmpdir/archive.tar.gz" file.txt
tar -C "$tmpdir/outdir" -xzf "$tmpdir/archive.tar.gz"
validator_assert_contains "$tmpdir/outdir/file.txt" 'tar gzip payload'
