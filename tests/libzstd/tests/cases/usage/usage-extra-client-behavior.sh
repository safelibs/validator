#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_tree() {
  mkdir -p "$tmpdir/in/dir/sub" "$tmpdir/out"
  printf 'alpha payload\n' >"$tmpdir/in/alpha.txt"
  printf 'beta payload\n' >"$tmpdir/in/dir/beta.txt"
  printf 'gamma payload\n' >"$tmpdir/in/dir/sub/gamma.txt"
  printf 'space payload\n' >"$tmpdir/in/space name.txt"
}

case "$case_id" in
  usage-libarchive-tools-zstd-multi-file)
    make_tree
    bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" alpha.txt dir/beta.txt
    bsdtar -tf "$tmpdir/a.tar.zstd" | tee "$tmpdir/list"
    validator_assert_contains "$tmpdir/list" 'alpha.txt'
    validator_assert_contains "$tmpdir/list" 'dir/beta.txt'
    ;;
  usage-libarchive-tools-zstd-nested-extract)
    make_tree
    bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" dir
    bsdtar -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out"
    validator_assert_contains "$tmpdir/out/dir/sub/gamma.txt" 'gamma payload'
    ;;
  usage-libarchive-tools-zstd-strip-components)
    make_tree
    bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" dir/sub/gamma.txt
    bsdtar --strip-components 2 -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out"
    validator_assert_contains "$tmpdir/out/gamma.txt" 'gamma payload'
    ;;
  usage-libarchive-tools-zstd-stdin-archive)
    make_tree
    bsdtar --zstd -cf "$tmpdir/stdin.tar.zstd" -C "$tmpdir/in" alpha.txt
    bsdtar -tf "$tmpdir/stdin.tar.zstd" | tee "$tmpdir/list"
    validator_assert_contains "$tmpdir/list" 'alpha.txt'
    ;;
  usage-libarchive-tools-zstd-single-file-extract)
    make_tree
    bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" alpha.txt dir/beta.txt
    bsdtar -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out" dir/beta.txt
    validator_assert_contains "$tmpdir/out/dir/beta.txt" 'beta payload'
    test ! -e "$tmpdir/out/alpha.txt"
    ;;
  usage-libarchive-tools-zstd-exclude-pattern)
    make_tree
    bsdtar --exclude '*beta*' --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" .
    bsdtar -tf "$tmpdir/a.tar.zstd" | tee "$tmpdir/list"
    validator_assert_contains "$tmpdir/list" 'alpha.txt'
    if grep -Fq 'beta.txt' "$tmpdir/list"; then exit 1; fi
    ;;
  usage-libarchive-tools-zstd-spaced-filename)
    make_tree
    bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" 'space name.txt'
    bsdtar -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out"
    validator_assert_contains "$tmpdir/out/space name.txt" 'space payload'
    ;;
  usage-libarchive-tools-zstd-checksum-compare)
    make_tree
    bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" alpha.txt
    bsdtar -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out"
    sha256sum "$tmpdir/in/alpha.txt" "$tmpdir/out/alpha.txt" | awk '{print $1}' >"$tmpdir/sums"
    test "$(sort -u "$tmpdir/sums" | wc -l)" -eq 1
    ;;
  usage-libarchive-tools-zstd-verbose-list)
    make_tree
    chmod 755 "$tmpdir/in/alpha.txt"
    bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" alpha.txt
    bsdtar -tvf "$tmpdir/a.tar.zstd" | tee "$tmpdir/list"
    grep -Eq '^-rwx' "$tmpdir/list"
    ;;
  usage-libarchive-tools-zstd-directory-only)
    mkdir -p "$tmpdir/in/empty" "$tmpdir/out"
    bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" empty
    bsdtar -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out"
    validator_require_dir "$tmpdir/out/empty"
    ;;
  *)
    printf 'unknown libzstd extra usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
