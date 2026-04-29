#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-escape-text
# @title: xmlstarlet escapes text
# @description: Escapes text through xmlstarlet and verifies XML entities.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-escape-text"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'a < b & c\n' | xmlstarlet esc | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'a &lt; b &amp; c'
