#!/usr/bin/env bash
# @testcase: usage-tar-r19-numeric-owner-restore
# @title: tar --numeric-owner restores numeric uid/gid from a created archive
# @description: Creates a file, archives it with tar --numeric-owner, extracts into a fresh directory, then stats the extracted file and asserts its numeric uid equals the current process uid - locking in libc-backed numeric ownership preservation through tar.
# @timeout: 30
# @tags: usage, tar, numeric-owner, r19
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'numeric-owner-payload\n' >"$tmpdir/file.txt"
cd "$tmpdir"
tar --numeric-owner -cf out.tar file.txt

mkdir -p "$tmpdir/extract"
tar --numeric-owner -xf out.tar -C "$tmpdir/extract"

want_uid=$(id -u)
got_uid=$(stat -c '%u' "$tmpdir/extract/file.txt")
[[ "$got_uid" == "$want_uid" ]] || {
    printf 'expected uid %s, got %s\n' "$want_uid" "$got_uid" >&2
    exit 1
}
