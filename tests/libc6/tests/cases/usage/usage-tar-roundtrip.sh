#!/usr/bin/env bash
# @testcase: usage-tar-roundtrip
# @title: tar archives file
# @description: Creates and extracts a tar archive while preserving file content.
# @timeout: 120
# @tags: usage, archive
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-tar-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src" "$tmpdir/outdir"
printf 'tar payload\n' >"$tmpdir/src/file.txt"
tar -C "$tmpdir/src" -cf "$tmpdir/archive.tar" file.txt
tar -C "$tmpdir/outdir" -xf "$tmpdir/archive.tar"
validator_assert_contains "$tmpdir/outdir/file.txt" 'tar payload'
