#!/usr/bin/env bash
# @testcase: usage-gio-info-directory-type
# @title: gio info directory type
# @description: Runs gio info on a directory path and verifies the type field is reported as directory in the human-readable summary.
# @timeout: 120
# @tags: usage, gio, attributes
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-info-directory-type"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/folder"
gio info "$tmpdir/folder" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'type: directory'
validator_assert_contains "$tmpdir/out" 'name: folder'
