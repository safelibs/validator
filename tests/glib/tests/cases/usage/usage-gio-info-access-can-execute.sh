#!/usr/bin/env bash
# @testcase: usage-gio-info-access-can-execute
# @title: gio info access::can-execute reflects mode
# @description: Compares the access::can-execute attribute reported by gio info before and after toggling the executable bit on a temp file.
# @timeout: 120
# @tags: usage, gio, attributes
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-info-access-can-execute"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '#!/bin/sh\necho hi\n' >"$tmpdir/script.sh"
chmod 0644 "$tmpdir/script.sh"
gio info -a access::can-execute "$tmpdir/script.sh" >"$tmpdir/before"
validator_assert_contains "$tmpdir/before" 'access::can-execute: FALSE'

chmod 0755 "$tmpdir/script.sh"
gio info -a access::can-execute "$tmpdir/script.sh" >"$tmpdir/after"
validator_assert_contains "$tmpdir/after" 'access::can-execute: TRUE'
