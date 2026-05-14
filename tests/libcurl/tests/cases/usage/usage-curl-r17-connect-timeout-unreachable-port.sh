#!/usr/bin/env bash
# @testcase: usage-curl-r17-connect-timeout-unreachable-port
# @title: curl --connect-timeout exits 28 for an unreachable address within the bound
# @description: Runs curl with --connect-timeout 1 against a non-routable address (203.0.113.1, TEST-NET-3) and asserts the exit code is 28 — locking in the connect-phase timeout exit code for an unreachable peer.
# @timeout: 30
# @tags: usage, curl, connect-timeout
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

set +e
curl --noproxy '*' --silent --connect-timeout 1 --max-time 5 \
    -o /dev/null "http://203.0.113.1:80/" 2>/dev/null
rc=$?
set -e

[[ "$rc" -eq 28 ]] || {
    printf 'expected curl exit 28 for connect-timeout, got %s\n' "$rc" >&2
    exit 1
}
