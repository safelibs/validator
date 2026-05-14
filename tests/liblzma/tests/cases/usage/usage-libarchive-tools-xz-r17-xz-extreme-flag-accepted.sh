#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r17-xz-extreme-flag-accepted
# @title: xz -e (extreme) accepts a tiny payload and round-trips bytes
# @description: Compresses a small payload with xz -9 -e, decompresses, and asserts the round-tripped payload matches the original SHA — locking the --extreme flag's behavior on the lzma-utils CLI as installed.
# @timeout: 60
# @tags: usage, xz, extreme
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r17-extreme-payload-%s\n' 'short-data' >"$tmpdir/in.txt"
original_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz -9 -e -c "$tmpdir/in.txt" >"$tmpdir/out.xz"
validator_require_file "$tmpdir/out.xz"

xz -d -c "$tmpdir/out.xz" >"$tmpdir/round.txt"
round_sha=$(sha256sum "$tmpdir/round.txt" | awk '{print $1}')
[[ "$original_sha" == "$round_sha" ]] || {
  printf 'sha mismatch\n' >&2; exit 1
}
