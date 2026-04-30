#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch16-tvjf-user-group
# @title: bsdtar -tvJf shows user/group
# @description: Creates an xz tarball as the current user, then runs bsdtar -tvJf and confirms the listing includes the expected user/group fields.
# @timeout: 180
# @tags: usage, archive, xz, verbose
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'verbose payload\n' >"$tmpdir/src/verbose.txt"

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/src" verbose.txt

# Capture the verbose listing.
bsdtar -tvJf "$tmpdir/a.tar.xz" >"$tmpdir/list"

# The listing should reference the entry name.
validator_assert_contains "$tmpdir/list" 'verbose.txt'

# Determine current user/group as bsdtar would have stamped them when no
# explicit owner override is passed.
cur_user=$(id -un)
cur_group=$(id -gn)

# bsdtar -tv formats user/group as "user/group". Fall back to checking either
# token individually if the combined "user/group" form is not present (covers
# environments where uname is unavailable and numeric ids are emitted).
if grep -Fq -- "${cur_user}/${cur_group}" "$tmpdir/list"; then
  :
else
  # Both tokens must still appear somewhere in the verbose line.
  validator_assert_contains "$tmpdir/list" "$cur_user"
  validator_assert_contains "$tmpdir/list" "$cur_group"
fi
