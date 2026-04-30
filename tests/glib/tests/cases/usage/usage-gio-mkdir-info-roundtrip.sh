#!/usr/bin/env bash
# @testcase: usage-gio-mkdir-info-roundtrip
# @title: gio mkdir then info round-trip
# @description: Creates a directory through gio mkdir, then queries it back with gio info and verifies the standard::type reports as directory.
# @timeout: 180
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-mkdir-info-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

target="$tmpdir/round-trip-dir"
gio mkdir "$target"
validator_require_dir "$target"

gio info -a standard::type,standard::name "$target" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'standard::type:'
validator_assert_contains "$tmpdir/out" 'directory'
validator_assert_contains "$tmpdir/out" 'round-trip-dir'
