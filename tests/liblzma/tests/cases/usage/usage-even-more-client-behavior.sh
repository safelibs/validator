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
  usage-libarchive-tools-xz-rootdir-list)
    make_tree
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir" in
    bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/list"
    validator_assert_contains "$tmpdir/list" 'in/alpha.txt'
    ;;
  usage-libarchive-tools-xz-rootdir-extract-gamma)
    make_tree
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir" in
    bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out" in/dir/sub/gamma.txt
    validator_assert_contains "$tmpdir/out/in/dir/sub/gamma.txt" 'gamma payload'
    ;;
  usage-libarchive-tools-xz-symlink-extract-target)
    mkdir -p "$tmpdir/in" "$tmpdir/out"
    printf 'symlink payload\n' >"$tmpdir/in/original.txt"
    ln -s original.txt "$tmpdir/in/original.link"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" original.txt original.link
    bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
    test "$(readlink "$tmpdir/out/original.link")" = 'original.txt'
    ;;
  usage-libarchive-tools-xz-filelist-space-name)
    make_tree
    printf 'space name.txt\n' >"$tmpdir/files.txt"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" -T "$tmpdir/files.txt"
    bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
    validator_assert_contains "$tmpdir/out/space name.txt" 'space payload'
    ;;
  usage-libarchive-tools-xz-stream-member-stdout)
    make_tree
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" dir/sub/gamma.txt
    cat "$tmpdir/a.tar.xz" | bsdtar -xOf - dir/sub/gamma.txt >"$tmpdir/out.txt"
    validator_assert_contains "$tmpdir/out.txt" 'gamma payload'
    ;;
  usage-libarchive-tools-xz-hidden-visible-list)
    mkdir -p "$tmpdir/in"
    printf 'hidden payload\n' >"$tmpdir/in/.hidden"
    printf 'visible payload\n' >"$tmpdir/in/visible.txt"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" .hidden visible.txt
    bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/list"
    validator_assert_contains "$tmpdir/list" '.hidden'
    validator_assert_contains "$tmpdir/list" 'visible.txt'
    ;;
  usage-libarchive-tools-xz-hardlink-extract-compare)
    mkdir -p "$tmpdir/in" "$tmpdir/out"
    printf 'link payload\n' >"$tmpdir/in/original.txt"
    ln "$tmpdir/in/original.txt" "$tmpdir/in/original.hard"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" original.txt original.hard
    bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
    cmp -s "$tmpdir/out/original.txt" "$tmpdir/out/original.hard"
    ;;
  usage-libarchive-tools-xz-empty-subdir-extract)
    mkdir -p "$tmpdir/in/empty/sub" "$tmpdir/out"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" empty
    bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
    validator_require_dir "$tmpdir/out/empty/sub"
    ;;
  usage-libarchive-tools-xz-space-dir-list)
    mkdir -p "$tmpdir/in/space dir"
    printf 'space dir payload\n' >"$tmpdir/in/space dir/item.txt"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" 'space dir'
    bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/list"
    validator_assert_contains "$tmpdir/list" 'space dir/item.txt'
    ;;
  usage-libarchive-tools-xz-dotfile-stream-extract)
    mkdir -p "$tmpdir/in"
    printf 'dotfile payload\n' >"$tmpdir/in/.hidden"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" .hidden
    cat "$tmpdir/a.tar.xz" | bsdtar -xOf - .hidden >"$tmpdir/out.txt"
    validator_assert_contains "$tmpdir/out.txt" 'dotfile payload'
    ;;
  *)
    printf 'unknown liblzma even-more usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
