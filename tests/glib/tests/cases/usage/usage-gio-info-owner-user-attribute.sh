#!/usr/bin/env bash
# @testcase: usage-gio-info-owner-user-attribute
# @title: gio info owner user attribute
# @description: Requests the owner::user attribute via gio info -a and verifies the printed user matches the current process owner reported by id -un.
# @timeout: 120
# @tags: usage, gio, attributes
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-info-owner-user-attribute"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'owner payload\n' >"$tmpdir/file.txt"
expected_user=$(id -un)
gio info -a owner::user "$tmpdir/file.txt" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" "owner::user: ${expected_user}"
