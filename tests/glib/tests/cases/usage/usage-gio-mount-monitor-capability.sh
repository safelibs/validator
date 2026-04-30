#!/usr/bin/env bash
# @testcase: usage-gio-mount-monitor-capability
# @title: gio mount help advertises monitor capability
# @description: Inspects gio help mount and the gio mount synopsis to verify the monitor and list capabilities (used to observe volume monitor events) are advertised in the option banner.
# @timeout: 60
# @tags: usage, gio, help, mount
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-mount-monitor-capability"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# `gio help mount` prints the canonical option summary to stdout.
gio help mount >"$tmpdir/help" 2>&1
validator_assert_contains "$tmpdir/help" 'Usage:'
validator_assert_contains "$tmpdir/help" 'gio mount'

# The option banner lists --monitor and --list capabilities.
validator_assert_contains "$tmpdir/help" '--monitor'
validator_assert_contains "$tmpdir/help" '--list'

# Cross-check by asking gio mount itself for an unknown flag, which
# echoes the same option summary on stderr.
gio mount --not-a-real-flag >"$tmpdir/synopsis" 2>&1 || true
validator_assert_contains "$tmpdir/synopsis" '--monitor'
