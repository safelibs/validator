#!/usr/bin/env bash
# @testcase: usage-gio-r14-info-attributes-glob-listing
# @title: gio info --attributes='*' includes both standard and unix namespaces
# @description: Creates a probe file and calls gio info --attributes='*' on it, asserting the output exposes attributes from multiple namespaces including standard::name, standard::type, and unix::mode.
# @timeout: 60
# @tags: usage, gio, attributes
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'attr glob\n' >"$tmpdir/probe.txt"
gio info --attributes='*' "$tmpdir/probe.txt" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'standard::name:'
validator_assert_contains "$tmpdir/out" 'standard::type:'
validator_assert_contains "$tmpdir/out" 'unix::mode:'
