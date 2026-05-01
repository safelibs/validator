#!/usr/bin/env bash
# @testcase: usage-python3-os-confstr-libc-version
# @title: python3 os.confstr exposes glibc runtime info
# @description: Calls os.confstr('CS_GNU_LIBC_VERSION') to read the GNU libc release string at runtime and confirms the response begins with 'glibc'.
# @timeout: 120
# @tags: usage, python, libc
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-os-confstr-libc-version"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import os
value = os.confstr('CS_GNU_LIBC_VERSION') or ''
print(f"libc={value}")
PYCASE

validator_assert_contains "$tmpdir/out" 'libc=glibc'
