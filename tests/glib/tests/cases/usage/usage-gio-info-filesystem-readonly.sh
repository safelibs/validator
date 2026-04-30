#!/usr/bin/env bash
# @testcase: usage-gio-info-filesystem-readonly
# @title: gio info filesystem readonly attribute
# @description: Queries the filesystem::readonly attribute via gio info --filesystem on a writable temp directory and verifies the attribute is reported as FALSE.
# @timeout: 120
# @tags: usage, gio
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-info-filesystem-readonly"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/probe"
gio info --filesystem "$tmpdir/probe" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'filesystem::readonly:'
validator_assert_contains "$tmpdir/out" 'filesystem::readonly: FALSE'
