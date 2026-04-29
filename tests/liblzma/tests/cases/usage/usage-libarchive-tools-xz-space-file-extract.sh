#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-space-file-extract
# @title: libarchive-tools xz space file extract
# @description: Extracts a spaced filename from an xz-compressed tar archive and verifies the restored file payload.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-space-file-extract"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

archive="$tmpdir/archive.tar.xz"

build_archive() {
  rm -rf "$tmpdir/src" "$tmpdir/out" "$archive"
  mkdir -p "$tmpdir/src/dir"
  printf 'alpha payload\n' >"$tmpdir/src/alpha.txt"
  printf 'beta payload\n' >"$tmpdir/src/dir/beta.txt"
  printf 'hidden payload\n' >"$tmpdir/src/.hidden"
  printf 'space payload\n' >"$tmpdir/src/dir/space name.txt"
  : >"$tmpdir/src/empty.txt"
  printf '#!/usr/bin/env bash\nexit 0\n' >"$tmpdir/src/run.sh"
  chmod 755 "$tmpdir/src/run.sh"
  bsdtar -acf "$archive" -C "$tmpdir/src" .
}

build_archive
mkdir -p "$tmpdir/out"
bsdtar -xvf "$archive" -C "$tmpdir/out" './dir/space name.txt' >"$tmpdir/log"
validator_assert_contains "$tmpdir/out/dir/space name.txt" 'space payload'
