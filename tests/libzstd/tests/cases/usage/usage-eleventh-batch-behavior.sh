#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_archive() {
  mkdir -p "$tmpdir/src/top/nested" "$tmpdir/src/space dir"
  printf 'alpha payload\n' >"$tmpdir/src/top/alpha.txt"
  printf 'beta payload\n' >"$tmpdir/src/top/nested/beta.txt"
  printf 'space payload\n' >"$tmpdir/src/space dir/file name.txt"
  printf 'skip payload\n' >"$tmpdir/src/top/skip.tmp"
  bsdtar -acf "$tmpdir/archive.tar.zst" -C "$tmpdir/src" .
}

case "$case_id" in
  usage-libarchive-tools-zstd-batch11-list-nested)
    make_archive
    bsdtar -tf "$tmpdir/archive.tar.zst" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" './top/nested/beta.txt'
    ;;
  usage-libarchive-tools-zstd-batch11-stdout-alpha)
    make_archive
    bsdtar -xOf "$tmpdir/archive.tar.zst" ./top/alpha.txt >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alpha payload'
    ;;
  usage-libarchive-tools-zstd-batch11-extract-specific)
    make_archive
    mkdir "$tmpdir/dest"
    bsdtar -xf "$tmpdir/archive.tar.zst" -C "$tmpdir/dest" ./top/nested/beta.txt
    validator_assert_contains "$tmpdir/dest/top/nested/beta.txt" 'beta payload'
    ;;
  usage-libarchive-tools-zstd-batch11-exclude-temp)
    make_archive
    mkdir "$tmpdir/dest"
    bsdtar -xf "$tmpdir/archive.tar.zst" -C "$tmpdir/dest" --exclude '*.tmp'
    test ! -e "$tmpdir/dest/top/skip.tmp"
    ;;
  usage-libarchive-tools-zstd-batch11-strip-components)
    make_archive
    mkdir "$tmpdir/dest"
    bsdtar --strip-components 2 -xf "$tmpdir/archive.tar.zst" -C "$tmpdir/dest" ./top/alpha.txt
    validator_assert_contains "$tmpdir/dest/alpha.txt" 'alpha payload'
    ;;
  usage-libarchive-tools-zstd-batch11-stdin-list)
    make_archive
    bsdtar -tf - <"$tmpdir/archive.tar.zst" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" './top/alpha.txt'
    ;;
  usage-libarchive-tools-zstd-batch11-space-name-stdout)
    make_archive
    bsdtar -xOf "$tmpdir/archive.tar.zst" './space dir/file name.txt' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'space payload'
    ;;
  usage-libarchive-tools-zstd-batch11-checksum-compare)
    make_archive
    mkdir "$tmpdir/dest"
    bsdtar -xf "$tmpdir/archive.tar.zst" -C "$tmpdir/dest" ./top/alpha.txt
    sha256sum "$tmpdir/src/top/alpha.txt" "$tmpdir/dest/top/alpha.txt" | awk '{print $1}' >"$tmpdir/sums"
    test "$(sort -u "$tmpdir/sums" | wc -l)" -eq 1
    ;;
  usage-libarchive-tools-zstd-batch11-verbose-list)
    make_archive
    bsdtar -tvf "$tmpdir/archive.tar.zst" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alpha.txt'
    ;;
  usage-libarchive-tools-zstd-batch11-copy-archive-file)
    make_archive
    cp "$tmpdir/archive.tar.zst" "$tmpdir/copy.tzst"
    bsdtar -tf "$tmpdir/copy.tzst" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" './space dir/file name.txt'
    ;;
  *)
    printf 'unknown libzstd eleventh-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
