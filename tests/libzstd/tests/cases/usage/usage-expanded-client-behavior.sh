#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

archive="$tmpdir/archive.tar.zst"

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

case "$case_id" in
  usage-libarchive-tools-zstd-stdout-member-alpha)
    build_archive
    bsdtar -xOf "$archive" ./alpha.txt >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alpha payload'
    ;;
  usage-libarchive-tools-zstd-stdin-list-members)
    build_archive
    cat "$archive" | bsdtar -tf - >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" './alpha.txt'
    validator_assert_contains "$tmpdir/out" './dir/beta.txt'
    ;;
  usage-libarchive-tools-zstd-space-file-stdout)
    build_archive
    bsdtar -xOf "$archive" './dir/space name.txt' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'space payload'
    ;;
  usage-libarchive-tools-zstd-verbose-exec-list)
    build_archive
    bsdtar -tvf "$archive" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'run.sh'
    validator_assert_contains "$tmpdir/out" 'rwxr-xr-x'
    ;;
  usage-libarchive-tools-zstd-extract-specific-member)
    build_archive
    mkdir -p "$tmpdir/out"
    bsdtar -xvf "$archive" -C "$tmpdir/out" ./dir/beta.txt >"$tmpdir/log"
    validator_assert_contains "$tmpdir/out/dir/beta.txt" 'beta payload'
    ;;
  usage-libarchive-tools-zstd-empty-file-size)
    build_archive
    bsdtar -tvf "$archive" >"$tmpdir/out"
    grep -E '[[:space:]]0[[:space:]]+.*empty\.txt' "$tmpdir/out" >/dev/null
    ;;
  usage-libarchive-tools-zstd-two-space-files-list)
    build_archive
    bsdtar -tf "$archive" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" './dir/space name.txt'
    validator_assert_contains "$tmpdir/out" './alpha.txt'
    ;;
  usage-libarchive-tools-zstd-member-count-three-plus)
    build_archive
    count=$(bsdtar -tf "$archive" | wc -l)
    test "$count" -ge 5
    ;;
  usage-libarchive-tools-zstd-dotfile-stdout)
    build_archive
    bsdtar -xOf "$archive" ./.hidden >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'hidden payload'
    ;;
  usage-libarchive-tools-zstd-space-file-extract)
    build_archive
    mkdir -p "$tmpdir/out"
    bsdtar -xvf "$archive" -C "$tmpdir/out" './dir/space name.txt' >"$tmpdir/log"
    validator_assert_contains "$tmpdir/out/dir/space name.txt" 'space payload'
    ;;
  *)
    printf 'unknown libzstd expanded usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
