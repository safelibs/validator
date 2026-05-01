#!/usr/bin/env bash
# @testcase: usage-python3-gi-checksum-update-incremental
# @title: PyGObject GLib Checksum incremental update
# @description: Feeds a payload to GLib.Checksum in two update() calls through PyGObject and verifies the digest matches a single-shot hash of the same bytes.
# @timeout: 180
# @tags: usage, python, glib, checksum
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-checksum-update-incremental"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

part_a = b'incremental '
part_b = b'payload bytes'
combined = part_a + part_b

streaming = GLib.Checksum.new(GLib.ChecksumType.SHA256)
streaming.update(part_a)
streaming.update(part_b)
incremental_digest = streaming.get_string()

oneshot_digest = GLib.compute_checksum_for_data(GLib.ChecksumType.SHA256, combined)

print('incremental=' + incremental_digest)
print('oneshot=' + oneshot_digest)
print('match=' + str(incremental_digest == oneshot_digest))
PY

validator_assert_contains "$tmpdir/out" 'match=True'
# Known SHA-256 of "incremental payload bytes":
validator_assert_contains "$tmpdir/out" 'oneshot=7f0133ab6671c0dd1e40a4fdc5cad3d3180d960257fceb0fbdce71904fbb0f5e'
