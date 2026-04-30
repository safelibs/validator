#!/usr/bin/env bash
# @testcase: usage-gio-mkdir-parents-nested
# @title: gio mkdir parents nested
# @description: Creates a nested directory chain through gio mkdir --parent and verifies every intermediate directory exists.
# @timeout: 180
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-mkdir-parents-nested"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

target="$tmpdir/alpha/beta/gamma"
gio mkdir --parent "$target"

validator_require_dir "$tmpdir/alpha"
validator_require_dir "$tmpdir/alpha/beta"
validator_require_dir "$tmpdir/alpha/beta/gamma"
