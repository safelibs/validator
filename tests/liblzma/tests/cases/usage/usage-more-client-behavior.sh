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
  usage-libarchive-tools-xz-topdir-strip-one)
    make_tree
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir" in
    bsdtar --strip-components 1 -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
    validator_assert_contains "$tmpdir/out/alpha.txt" 'alpha payload'
    validator_assert_contains "$tmpdir/out/dir/beta.txt" 'beta payload'
    ;;
  usage-libarchive-tools-xz-filelist-stdin)
    make_tree
    printf 'alpha.txt\ndir/sub/gamma.txt\n' | bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" -T -
    bsdtar -tf "$tmpdir/a.tar.xz" | tee "$tmpdir/list"
    validator_assert_contains "$tmpdir/list" 'alpha.txt'
    validator_assert_contains "$tmpdir/list" 'dir/sub/gamma.txt'
    ;;
  usage-libarchive-tools-xz-dotdir-entry)
    mkdir -p "$tmpdir/in/.config/sub" "$tmpdir/out"
    printf 'dotdir payload\n' >"$tmpdir/in/.config/sub/value.txt"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" .config
    bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
    validator_assert_contains "$tmpdir/out/.config/sub/value.txt" 'dotdir payload'
    ;;
  usage-libarchive-tools-xz-symlink-listing)
    mkdir -p "$tmpdir/in"
    printf 'symlink payload\n' >"$tmpdir/in/original.txt"
    ln -s original.txt "$tmpdir/in/original.link"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" original.txt original.link
    bsdtar -tvf "$tmpdir/a.tar.xz" | tee "$tmpdir/list"
    validator_assert_contains "$tmpdir/list" 'original.link'
    ;;
  usage-libarchive-tools-xz-member-order)
    make_tree
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" dir/beta.txt alpha.txt
    bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/list"
    first=$(sed -n '1p' "$tmpdir/list")
    second=$(sed -n '2p' "$tmpdir/list")
    test "$first" = 'dir/beta.txt'
    test "$second" = 'alpha.txt'
    ;;
  usage-libarchive-tools-xz-space-dir)
    mkdir -p "$tmpdir/in/space dir" "$tmpdir/out"
    printf 'space dir payload\n' >"$tmpdir/in/space dir/item.txt"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" 'space dir'
    bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
    validator_assert_contains "$tmpdir/out/space dir/item.txt" 'space dir payload'
    ;;
  usage-libarchive-tools-xz-extract-dotfile)
    mkdir -p "$tmpdir/in" "$tmpdir/out"
    printf 'hidden payload\n' >"$tmpdir/in/.hidden"
    printf 'visible payload\n' >"$tmpdir/in/visible.txt"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" .hidden visible.txt
    bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out" .hidden
    validator_assert_contains "$tmpdir/out/.hidden" 'hidden payload'
    test ! -e "$tmpdir/out/visible.txt"
    ;;
  usage-libarchive-tools-xz-multi-empty-files)
    mkdir -p "$tmpdir/in" "$tmpdir/out"
    : >"$tmpdir/in/one.txt"
    : >"$tmpdir/in/two.txt"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" one.txt two.txt
    bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
    test "$(wc -c <"$tmpdir/out/one.txt")" -eq 0
    test "$(wc -c <"$tmpdir/out/two.txt")" -eq 0
    ;;
  usage-libarchive-tools-xz-hardlink-listing)
    mkdir -p "$tmpdir/in"
    printf 'hardlink payload\n' >"$tmpdir/in/original.txt"
    ln "$tmpdir/in/original.txt" "$tmpdir/in/original.hard"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" original.txt original.hard
    bsdtar -tvf "$tmpdir/a.tar.xz" | tee "$tmpdir/list"
    validator_assert_contains "$tmpdir/list" 'original.hard'
    ;;
  usage-libarchive-tools-xz-dotdir-subtree)
    mkdir -p "$tmpdir/in/.cache/sub"
    printf 'cache payload\n' >"$tmpdir/in/.cache/sub/value.txt"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" .cache/sub
    bsdtar -tf "$tmpdir/a.tar.xz" | tee "$tmpdir/list"
    validator_assert_contains "$tmpdir/list" '.cache/sub/value.txt'
    ;;
  *)
    printf 'unknown liblzma additional usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
