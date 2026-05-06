#!/usr/bin/env bash
# @testcase: usage-gpg-r9-list-config-curve-nistp256
# @title: gpg --list-config curve includes nistp256
# @description: Calls gpg --list-config curve and verifies the supported-curves line includes nistp256 alongside other standard curves.
# @timeout: 60
# @tags: usage, gpg, curves
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gpg --with-colons --list-config curve >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'nistp256'
