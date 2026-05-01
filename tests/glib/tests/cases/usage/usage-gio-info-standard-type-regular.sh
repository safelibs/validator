#!/usr/bin/env bash
# @testcase: usage-gio-info-standard-type-regular
# @title: gio info standard type regular
# @description: Verifies gio info -a standard::type reports the integer file type code for a regular file under the standard namespace.
# @timeout: 120
# @tags: usage, gio, attributes
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-info-standard-type-regular"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'type probe\n' >"$tmpdir/regular.txt"
gio info -a standard::type "$tmpdir/regular.txt" >"$tmpdir/out"

# G_FILE_TYPE_REGULAR has integer value 1 in the GIO enumeration.
validator_assert_contains "$tmpdir/out" 'standard::type: 1'
