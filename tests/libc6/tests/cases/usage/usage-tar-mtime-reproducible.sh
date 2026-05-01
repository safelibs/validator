#!/usr/bin/env bash
# @testcase: usage-tar-mtime-reproducible
# @title: tar --mtime fixes archive timestamps
# @description: Builds two archives from the same payload using tar --mtime=@<epoch> --sort=name --owner=0 --group=0 --numeric-owner and asserts the byte streams are identical.
# @timeout: 120
# @tags: usage, tar, reproducible
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-tar-mtime-reproducible"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'alpha\n' >"$tmpdir/src/a.txt"
printf 'beta\n'  >"$tmpdir/src/b.txt"
printf 'gamma\n' >"$tmpdir/src/c.txt"

build() {
  tar --mtime='@1700000000' \
      --sort=name \
      --owner=0 --group=0 --numeric-owner \
      -cf "$1" -C "$tmpdir/src" .
}

build "$tmpdir/one.tar"
# Touch source files to a different mtime to confirm --mtime overrides on-disk values.
find "$tmpdir/src" -type f -exec touch -d '@1500000000' {} +
build "$tmpdir/two.tar"

cmp "$tmpdir/one.tar" "$tmpdir/two.tar"
