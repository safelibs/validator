#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-force-overwrite
# @title: zstd CLI -f force overwrite of existing output
# @description: Compresses a payload with the zstd CLI to a target path that already exists, confirms that without -f the CLI refuses to clobber, and that re-running with -f succeeds and the resulting frame round-trips to the new payload.
# @timeout: 120
# @tags: usage, archive, zstd, cli
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.txt"
printf 'force-overwrite payload v2\n' >"$src"

# Pre-create the target file with stale contents.
printf 'stale\n' >"$tmpdir/out.zst"
stale_sum=$(sha256sum "$tmpdir/out.zst" | awk '{print $1}')

# Without -f and without an interactive TTY, zstd must refuse to overwrite.
set +e
zstd -q -o "$tmpdir/out.zst" "$src" </dev/null >/dev/null 2>&1
rc_no_force=$?
set -e
test "$rc_no_force" -ne 0
# Stale contents must still be present.
current_sum=$(sha256sum "$tmpdir/out.zst" | awk '{print $1}')
test "$current_sum" = "$stale_sum"

# With -f the same invocation must succeed and replace the file with a real
# zstd frame.
zstd -qf -o "$tmpdir/out.zst" "$src"
validator_require_file "$tmpdir/out.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/out.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd -tq "$tmpdir/out.zst"
zstd -dq -c "$tmpdir/out.zst" >"$tmpdir/decoded.txt"
cmp "$src" "$tmpdir/decoded.txt"
