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
  bsdtar -acf "$tmpdir/archive.tar.xz" -C "$tmpdir/src" .
}

case "$case_id" in
  usage-libarchive-tools-xz-batch11-filelist-create)
    mkdir -p "$tmpdir/src"
    printf 'one\n' >"$tmpdir/src/one.txt"
    printf 'two\n' >"$tmpdir/src/two.txt"
    printf 'one.txt\ntwo.txt\n' >"$tmpdir/list"
    bsdtar -acf "$tmpdir/archive.tar.xz" -C "$tmpdir/src" -T "$tmpdir/list"
    bsdtar -tf "$tmpdir/archive.tar.xz" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'one.txt'
    validator_assert_contains "$tmpdir/out" 'two.txt'
    ;;
  usage-libarchive-tools-xz-batch11-null-filelist)
    mkdir -p "$tmpdir/src"
    printf 'alpha\n' >"$tmpdir/src/alpha.txt"
    printf 'beta\n' >"$tmpdir/src/beta.txt"
    printf 'alpha.txt\0beta.txt\0' >"$tmpdir/list0"
    bsdtar --null -acf "$tmpdir/archive.tar.xz" -C "$tmpdir/src" -T "$tmpdir/list0"
    bsdtar -tf "$tmpdir/archive.tar.xz" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alpha.txt'
    validator_assert_contains "$tmpdir/out" 'beta.txt'
    ;;
  usage-libarchive-tools-xz-batch11-empty-directory)
    mkdir -p "$tmpdir/src/empty"
    bsdtar -acf "$tmpdir/archive.tar.xz" -C "$tmpdir/src" empty
    mkdir "$tmpdir/outdir"
    bsdtar -xf "$tmpdir/archive.tar.xz" -C "$tmpdir/outdir"
    test -d "$tmpdir/outdir/empty"
    ;;
  usage-libarchive-tools-xz-batch11-mode-preserved)
    mkdir -p "$tmpdir/src"
    printf '#!/bin/sh\n' >"$tmpdir/src/tool.sh"
    chmod 700 "$tmpdir/src/tool.sh"
    bsdtar -acf "$tmpdir/archive.tar.xz" -C "$tmpdir/src" tool.sh
    mkdir "$tmpdir/outdir"
    bsdtar -xf "$tmpdir/archive.tar.xz" -C "$tmpdir/outdir"
    test "$(stat -c %a "$tmpdir/outdir/tool.sh")" = 700
    ;;
  usage-libarchive-tools-xz-batch11-mtime-preserved)
    mkdir -p "$tmpdir/src"
    printf 'dated\n' >"$tmpdir/src/dated.txt"
    touch -t 202001020304 "$tmpdir/src/dated.txt"
    bsdtar -acf "$tmpdir/archive.tar.xz" -C "$tmpdir/src" dated.txt
    mkdir "$tmpdir/outdir"
    bsdtar -xf "$tmpdir/archive.tar.xz" -C "$tmpdir/outdir"
    test "$(date -u -r "$tmpdir/outdir/dated.txt" +%Y%m%d%H%M)" = 202001020304
    ;;
  usage-libarchive-tools-xz-batch11-transform-name)
    mkdir -p "$tmpdir/src"
    printf 'rename\n' >"$tmpdir/src/oldname.txt"
    bsdtar -acf "$tmpdir/archive.tar.xz" -s /oldname/newname/ -C "$tmpdir/src" oldname.txt
    bsdtar -tf "$tmpdir/archive.tar.xz" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'newname.txt'
    ;;
  usage-libarchive-tools-xz-batch11-newer-mtime)
    mkdir -p "$tmpdir/src"
    printf 'old\n' >"$tmpdir/src/old.txt"
    printf 'new\n' >"$tmpdir/src/new.txt"
    touch -t 202001010000 "$tmpdir/src/old.txt"
    touch -t 202501010000 "$tmpdir/src/new.txt"
    bsdtar -acf "$tmpdir/archive.tar.xz" --newer-mtime "2024-01-01" -C "$tmpdir/src" old.txt new.txt
    bsdtar -tf "$tmpdir/archive.tar.xz" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'new.txt'
    if grep -Fq 'old.txt' "$tmpdir/out"; then exit 1; fi
    ;;
  usage-libarchive-tools-xz-batch11-owner-labels)
    mkdir -p "$tmpdir/src"
    printf 'owner\n' >"$tmpdir/src/owned.txt"
    bsdtar --uid 123 --gid 456 --uname validator --gname validators -acf "$tmpdir/archive.tar.xz" -C "$tmpdir/src" owned.txt
    bsdtar -tvf "$tmpdir/archive.tar.xz" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'validator'
    validator_assert_contains "$tmpdir/out" 'validators'
    ;;
  usage-libarchive-tools-xz-batch11-exclude-vcs)
    mkdir -p "$tmpdir/src/.git"
    printf 'data\n' >"$tmpdir/src/data.txt"
    printf 'config\n' >"$tmpdir/src/.git/config"
    bsdtar --exclude-vcs -acf "$tmpdir/archive.tar.xz" -C "$tmpdir/src" .
    bsdtar -tf "$tmpdir/archive.tar.xz" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" './data.txt'
    if grep -Fq '.git' "$tmpdir/out"; then exit 1; fi
    ;;
  usage-libarchive-tools-xz-batch11-ustar-format)
    mkdir -p "$tmpdir/src"
    printf 'ustar\n' >"$tmpdir/src/ustar.txt"
    bsdtar --format=ustar -acf "$tmpdir/archive.tar.xz" -C "$tmpdir/src" ustar.txt
    bsdtar -tf "$tmpdir/archive.tar.xz" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'ustar.txt'
    ;;
  *)
    printf 'unknown liblzma eleventh-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
