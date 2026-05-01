#!/usr/bin/env bash
# @testcase: usage-coreutils-realpath-symlink
# @title: coreutils realpath resolves symlinks
# @description: Creates a symlink chain and resolves it through realpath, asserting the canonical target path is returned.
# @timeout: 60
# @tags: usage, coreutils, filesystem
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-realpath-symlink"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/real"
target="$tmpdir/real/payload.txt"
printf 'real content\n' >"$target"

ln -s "$target" "$tmpdir/link1"
ln -s "$tmpdir/link1" "$tmpdir/link2"

resolved=$(realpath "$tmpdir/link2")
canonical=$(cd "$tmpdir/real" && pwd -P)/payload.txt

if [[ "$resolved" != "$canonical" ]]; then
  printf 'realpath mismatch: got %s expected %s\n' "$resolved" "$canonical" >&2
  exit 1
fi
