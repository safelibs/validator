#!/usr/bin/env bash
# @testcase: usage-bzip2-r19-bzip2-stdin-keep-flag-noop
# @title: bzip2 -k with stdin input writes to stdout without creating extra files in cwd
# @description: Runs bzip2 -k -c over a stdin redirection in a clean working directory, captures the compressed bytes to a file, and asserts no .bz2 or other artifacts appear in cwd while the captured archive decompresses back to the original payload - locking in stdin-mode neutrality of the -k flag.
# @timeout: 30
# @tags: usage, bzip2, keep, stdin, r19
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

workdir="$tmpdir/work"
mkdir -p "$workdir"
printf 'hello bzip2 stdin keep\n' >"$tmpdir/src.txt"

cd "$workdir"
bzip2 -k -c <"$tmpdir/src.txt" >"$tmpdir/out.bz2"

# work directory should be empty
remaining=$(ls -A "$workdir")
[[ -z "$remaining" ]] || {
    printf 'expected empty workdir, found: %s\n' "$remaining" >&2
    exit 1
}

bzip2 -dc "$tmpdir/out.bz2" >"$tmpdir/recovered.txt"
diff "$tmpdir/src.txt" "$tmpdir/recovered.txt"
