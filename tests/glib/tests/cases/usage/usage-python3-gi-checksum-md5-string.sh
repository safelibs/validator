#!/usr/bin/env bash
# @testcase: usage-python3-gi-checksum-md5-string
# @title: PyGObject GLib MD5 checksum
# @description: Computes an MD5 checksum with GLib through PyGObject and verifies the digest string is emitted.
# @timeout: 180
# @tags: usage, python, glib
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-checksum-md5-string"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
print(GLib.compute_checksum_for_string(GLib.ChecksumType.MD5, 'validator', -1))
PYCASE
validator_assert_contains "$tmpdir/out" '8d6c391e7cb39133c91b73281a24f21f'
