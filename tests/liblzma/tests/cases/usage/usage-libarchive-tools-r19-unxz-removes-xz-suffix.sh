#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r19-unxz-removes-xz-suffix
# @title: unxz decompresses file.xz to file and removes the .xz source by default
# @description: Compresses a file to .xz, runs unxz on the resulting .xz, then asserts the un-suffixed file exists with the original payload and the .xz source has been removed, pinning the default unxz file-rename contract.
# @timeout: 60
# @tags: usage, unxz, suffix, r19
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r19 unxz suffix payload\n' >"$tmpdir/data.txt"
src_sha=$(sha256sum "$tmpdir/data.txt" | awk '{print $1}')
xz "$tmpdir/data.txt"
[[ -f "$tmpdir/data.txt.xz" ]] || { printf 'expected xz file present\n' >&2; exit 1; }

unxz "$tmpdir/data.txt.xz"
[[ -f "$tmpdir/data.txt" ]] || { printf 'expected unxz output file\n' >&2; exit 1; }
[[ ! -e "$tmpdir/data.txt.xz" ]] || { printf 'xz source should have been removed\n' >&2; exit 1; }

dst_sha=$(sha256sum "$tmpdir/data.txt" | awk '{print $1}')
[[ "$src_sha" == "$dst_sha" ]]
