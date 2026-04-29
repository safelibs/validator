#!/usr/bin/env bash
# @testcase: usage-python3-minimal-os-strerror-batch11
# @title: Python os strerror
# @description: Formats a platform errno string through Python on libc.
# @timeout: 180
# @tags: usage, python, libc
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-minimal-os-strerror-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import os
print(os.strerror(2))
PYCASE
validator_assert_contains "$tmpdir/out" 'No such file'
