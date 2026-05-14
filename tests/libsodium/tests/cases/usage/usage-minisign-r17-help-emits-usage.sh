#!/usr/bin/env bash
# @testcase: usage-minisign-r17-help-emits-usage
# @title: minisign -h emits a usage block that mentions key generation and verification
# @description: Invokes "minisign -h" capturing both stdout and stderr, asserts the combined output contains "Usage:" and mentions both "-G" (key generation) and "-V" (verify), confirming the CLI's help banner is intact and documents the libsodium-backed signature subcommands.
# @timeout: 60
# @tags: usage, minisign, help, r17
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

minisign -h >"$tmpdir/help.out" 2>&1 || true
validator_assert_contains "$tmpdir/help.out" 'Usage:'
validator_assert_contains "$tmpdir/help.out" '-G'
validator_assert_contains "$tmpdir/help.out" '-V'
