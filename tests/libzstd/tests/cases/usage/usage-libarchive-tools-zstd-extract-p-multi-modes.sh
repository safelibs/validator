#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-extract-p-multi-modes
# @title: bsdtar zstd -xpf preserves multiple permission bit patterns
# @description: Archives several files carrying distinct permission bit patterns into a zstd-compressed tar and asserts that bsdtar -xpf restores each member's exact octal mode rather than only the executable bit.
# @timeout: 180
# @tags: usage, archive, zstd, metadata
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# A clean, world-permissive umask so the *create* step records the modes we
# set explicitly rather than whatever the runner's umask would mask away.
umask 0022

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'private payload\n' >"$tmpdir/in/private.dat"
printf 'group payload\n'   >"$tmpdir/in/group.dat"
printf 'exec payload\n'    >"$tmpdir/in/run.sh"
printf 'world payload\n'   >"$tmpdir/in/world.dat"

chmod 0600 "$tmpdir/in/private.dat"
chmod 0640 "$tmpdir/in/group.dat"
chmod 0750 "$tmpdir/in/run.sh"
chmod 0644 "$tmpdir/in/world.dat"

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" \
  private.dat group.dat run.sh world.dat
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

# -p forces bsdtar to restore stored permissions verbatim regardless of umask.
bsdtar -xpf "$tmpdir/a.tar.zst" -C "$tmpdir/out"

test "$(stat -c %a "$tmpdir/out/private.dat")" = "600"
test "$(stat -c %a "$tmpdir/out/group.dat")"   = "640"
test "$(stat -c %a "$tmpdir/out/run.sh")"      = "750"
test "$(stat -c %a "$tmpdir/out/world.dat")"   = "644"
