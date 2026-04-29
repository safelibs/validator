#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-member-count-three-plus
# @title: libarchive-tools xz member count three plus
# @description: Lists an xz-compressed tar archive and verifies that the archive contains multiple members beyond a minimal threshold.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-member-count-three-plus"
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
count=$(bsdtar -tf "$archive" | wc -l)
test "$count" -ge 5
