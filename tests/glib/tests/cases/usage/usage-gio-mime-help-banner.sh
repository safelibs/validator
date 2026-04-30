#!/usr/bin/env bash
# @testcase: usage-gio-mime-help-banner
# @title: gio mime --help banner mentions MIMETYPE
# @description: Invokes gio mime --help and verifies the per-subcommand synopsis advertises the MIMETYPE handler argument and a Usage line.
# @timeout: 60
# @tags: usage, gio, help
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-mime-help-banner"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# `gio mime --help` writes the synopsis to stdout on glib >= 2.68 and to
# stderr on older builds; merge streams to be portable. The command may
# also exit non-zero on some builds, so tolerate that and assert on the
# captured banner instead.
gio mime --help >"$tmpdir/out" 2>&1 || true

validator_assert_contains "$tmpdir/out" 'Usage:'
validator_assert_contains "$tmpdir/out" 'gio mime'
validator_assert_contains "$tmpdir/out" 'MIMETYPE'
