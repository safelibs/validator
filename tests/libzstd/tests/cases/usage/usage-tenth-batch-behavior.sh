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
  usage-libarchive-tools-zstd-batch10-stream-stdout-archive)
    make_tree
    bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" alpha.txt dir/beta.txt
    bsdtar -tf "$tmpdir/a.tar.zstd" >"$tmpdir/list"
    validator_assert_contains "$tmpdir/list" 'alpha.txt'
    validator_assert_contains "$tmpdir/list" 'dir/beta.txt'
    ;;
  usage-libarchive-tools-zstd-batch10-extract-stdin-piped)
    make_tree
    bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" dir/sub/gamma.txt
    mkdir -p "$tmpdir/out"
    bsdtar -xf - -C "$tmpdir/out" <"$tmpdir/a.tar.zstd"
    validator_assert_contains "$tmpdir/out/dir/sub/gamma.txt" 'gamma payload'
    ;;
  usage-libarchive-tools-zstd-batch10-exclude-multi)
    make_tree
    bsdtar --exclude '*alpha*' --exclude '*gamma*' --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" .
    bsdtar -tf "$tmpdir/a.tar.zstd" >"$tmpdir/list"
    validator_assert_contains "$tmpdir/list" 'beta.txt'
    if grep -Fq 'alpha.txt' "$tmpdir/list"; then exit 1; fi
    if grep -Fq 'gamma.txt' "$tmpdir/list"; then exit 1; fi
    ;;
  usage-libarchive-tools-zstd-batch10-roundtrip-checksum)
    make_tree
    bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" dir/beta.txt
    bsdtar -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out"
    sha256sum "$tmpdir/in/dir/beta.txt" "$tmpdir/out/dir/beta.txt" | awk '{print $1}' | sort -u >"$tmpdir/sums"
    test "$(wc -l <"$tmpdir/sums")" -eq 1
    ;;
  usage-libarchive-tools-zstd-batch10-cwd-extract)
    make_tree
    bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" alpha.txt
    mkdir -p "$tmpdir/out"
    (cd "$tmpdir/out" && bsdtar -xf "$tmpdir/a.tar.zstd")
    validator_assert_contains "$tmpdir/out/alpha.txt" 'alpha payload'
    ;;
  usage-libarchive-tools-zstd-batch10-multi-archive-list)
    make_tree
    bsdtar --zstd -cf "$tmpdir/one.tar.zstd" -C "$tmpdir/in" alpha.txt
    bsdtar --zstd -cf "$tmpdir/two.tar.zstd" -C "$tmpdir/in" 'space name.txt'
    bsdtar -tf "$tmpdir/one.tar.zstd" >"$tmpdir/list1"
    bsdtar -tf "$tmpdir/two.tar.zstd" >"$tmpdir/list2"
    validator_assert_contains "$tmpdir/list1" 'alpha.txt'
    validator_assert_contains "$tmpdir/list2" 'space name.txt'
    ;;
  usage-libarchive-tools-zstd-batch10-deep-nested-extract)
    mkdir -p "$tmpdir/in/a/b/c/d/e" "$tmpdir/out"
    printf 'deep payload\n' >"$tmpdir/in/a/b/c/d/e/leaf.txt"
    bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" a
    bsdtar -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out"
    validator_assert_contains "$tmpdir/out/a/b/c/d/e/leaf.txt" 'deep payload'
    ;;
  usage-libarchive-tools-zstd-batch10-mixed-format-list)
    make_tree
    bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" alpha.txt dir/beta.txt 'space name.txt'
    bsdtar -tf "$tmpdir/a.tar.zstd" >"$tmpdir/list"
    test "$(wc -l <"$tmpdir/list")" -eq 3
    validator_assert_contains "$tmpdir/list" 'alpha.txt'
    validator_assert_contains "$tmpdir/list" 'dir/beta.txt'
    validator_assert_contains "$tmpdir/list" 'space name.txt'
    ;;
  usage-libarchive-tools-zstd-batch10-extract-multi-stdout)
    make_tree
    bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" alpha.txt dir/beta.txt
    bsdtar -xOf "$tmpdir/a.tar.zstd" alpha.txt dir/beta.txt >"$tmpdir/out.txt"
    validator_assert_contains "$tmpdir/out.txt" 'alpha payload'
    validator_assert_contains "$tmpdir/out.txt" 'beta payload'
    ;;
  usage-libarchive-tools-zstd-batch10-zstd-decompress-flag)
    mkdir -p "$tmpdir/in" "$tmpdir/out"
    printf 'flag payload\n' >"$tmpdir/in/alpha.txt"
    bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" alpha.txt
    bsdtar --zstd -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out"
    validator_assert_contains "$tmpdir/out/alpha.txt" 'flag payload'
    ;;
  *)
    printf 'unknown libzstd tenth-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
