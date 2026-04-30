#!/usr/bin/env bash
# @testcase: usage-gio-info-filesystem-root
# @title: gio info filesystem attributes for root
# @description: Reads filesystem-level attributes for the root path through gio info --filesystem and verifies the standard filesystem type and size attributes are reported.
# @timeout: 180
# @tags: usage, gio
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-info-filesystem-root"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gio info --filesystem / >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'attributes:'
validator_assert_contains "$tmpdir/out" 'filesystem::size:'
validator_assert_contains "$tmpdir/out" 'filesystem::free:'
