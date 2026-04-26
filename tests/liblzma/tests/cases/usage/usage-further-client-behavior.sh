#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-libarchive-tools-xz-two-topdirs-list)
    mkdir -p "$tmpdir/in/top1" "$tmpdir/in/top2"
    printf 'alpha\n' >"$tmpdir/in/top1/alpha.txt"
    printf 'beta\n' >"$tmpdir/in/top2/beta.txt"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" top1 top2
    bsdtar -tf "$tmpdir/a.tar.xz" | tee "$tmpdir/list"
    validator_assert_contains "$tmpdir/list" 'top1/alpha.txt'
    validator_assert_contains "$tmpdir/list" 'top2/beta.txt'
    ;;
  usage-libarchive-tools-xz-rootdir-hidden-file)
    mkdir -p "$tmpdir/in/root" "$tmpdir/out"
    printf 'hidden payload\n' >"$tmpdir/in/root/.hidden"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" root
    bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
    validator_assert_contains "$tmpdir/out/root/.hidden" 'hidden payload'
    ;;
  usage-libarchive-tools-xz-nested-space-file)
    mkdir -p "$tmpdir/in/root/dir space" "$tmpdir/out"
    printf 'space payload\n' >"$tmpdir/in/root/dir space/delta.txt"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" 'root/dir space/delta.txt'
    bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
    validator_assert_contains "$tmpdir/out/root/dir space/delta.txt" 'space payload'
    ;;
  usage-libarchive-tools-xz-filelist-dotfile)
    mkdir -p "$tmpdir/in/root"
    printf 'alpha\n' >"$tmpdir/in/root/alpha.txt"
    printf 'hidden\n' >"$tmpdir/in/root/.hidden"
    printf 'root/.hidden\nroot/alpha.txt\n' >"$tmpdir/files.txt"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" -T "$tmpdir/files.txt"
    bsdtar -tf "$tmpdir/a.tar.xz" | tee "$tmpdir/list"
    validator_assert_contains "$tmpdir/list" 'root/.hidden'
    validator_assert_contains "$tmpdir/list" 'root/alpha.txt'
    ;;
  usage-libarchive-tools-xz-extract-two-members)
    mkdir -p "$tmpdir/in/root/dir/sub" "$tmpdir/out"
    printf 'alpha\n' >"$tmpdir/in/root/alpha.txt"
    printf 'beta\n' >"$tmpdir/in/root/dir/beta.txt"
    printf 'gamma\n' >"$tmpdir/in/root/dir/sub/gamma.txt"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" root
    bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out" root/alpha.txt root/dir/beta.txt
    validator_assert_contains "$tmpdir/out/root/alpha.txt" 'alpha'
    validator_assert_contains "$tmpdir/out/root/dir/beta.txt" 'beta'
    test ! -e "$tmpdir/out/root/dir/sub/gamma.txt"
    ;;
  usage-libarchive-tools-xz-double-strip-components)
    mkdir -p "$tmpdir/in/root/dir/sub" "$tmpdir/out"
    printf 'gamma\n' >"$tmpdir/in/root/dir/sub/gamma.txt"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" 'root/dir/sub/gamma.txt'
    bsdtar --strip-components 3 -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
    validator_assert_contains "$tmpdir/out/gamma.txt" 'gamma'
    ;;
  usage-libarchive-tools-xz-stream-subdir-list)
    mkdir -p "$tmpdir/in/root/dir/sub"
    printf 'gamma\n' >"$tmpdir/in/root/dir/sub/gamma.txt"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" root/dir/sub
    cat "$tmpdir/a.tar.xz" | bsdtar -tf - | tee "$tmpdir/list"
    validator_assert_contains "$tmpdir/list" 'root/dir/sub/gamma.txt'
    ;;
  usage-libarchive-tools-xz-space-rootdir-extract)
    mkdir -p "$tmpdir/in/space root" "$tmpdir/out"
    printf 'inner\n' >"$tmpdir/in/space root/inner.txt"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" 'space root'
    bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
    validator_assert_contains "$tmpdir/out/space root/inner.txt" 'inner'
    ;;
  usage-libarchive-tools-xz-hidden-and-visible-list)
    mkdir -p "$tmpdir/in"
    printf 'visible\n' >"$tmpdir/in/visible.txt"
    printf 'hidden\n' >"$tmpdir/in/.hidden"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" .hidden visible.txt
    bsdtar -tf "$tmpdir/a.tar.xz" | tee "$tmpdir/list"
    validator_assert_contains "$tmpdir/list" '.hidden'
    validator_assert_contains "$tmpdir/list" 'visible.txt'
    ;;
  usage-libarchive-tools-xz-space-rootdir-list)
    mkdir -p "$tmpdir/in/space root"
    printf 'inner\n' >"$tmpdir/in/space root/inner.txt"
    bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" 'space root'
    bsdtar -tf "$tmpdir/a.tar.xz" | tee "$tmpdir/list"
    validator_assert_contains "$tmpdir/list" 'space root/inner.txt'
    ;;
  *)
    printf 'unknown liblzma further usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
