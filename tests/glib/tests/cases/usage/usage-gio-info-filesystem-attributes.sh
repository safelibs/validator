#!/usr/bin/env bash
# @testcase: usage-gio-info-filesystem-attributes
# @title: gio info filesystem attributes
# @description: Reads filesystem-level attributes for a path through gio info --filesystem and verifies the standard filesystem type attribute is reported.
# @timeout: 180
# @tags: usage, gio
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-info-filesystem-attributes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/probe"
gio info --filesystem "$tmpdir/probe" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'filesystem::type:'
