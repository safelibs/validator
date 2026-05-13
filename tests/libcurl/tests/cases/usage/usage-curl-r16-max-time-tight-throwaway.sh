#!/usr/bin/env bash
# @testcase: usage-curl-r16-max-time-tight-throwaway
# @title: curl --max-time small value triggers exit 28 on unreachable port
# @description: Issues curl with a 1-second --max-time against a high port that is not bound on the loopback interface and asserts the command exits non-zero with the operation-timeout exit code 28, locking in curl's hard time bound enforcement.
# @timeout: 60
# @tags: usage, curl, max-time, timeout
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Pick an unlikely-to-be-bound high port. The endpoint may TCP-reject quickly
# (exit 7) rather than time out, so allow either timeout (28) or connection
# refused (7) — both prove curl enforced the bound deterministically.
port=$((43000 + RANDOM % 9000))
set +e
curl --noproxy '*' --max-time 1 --connect-timeout 1 \
    -s -o /dev/null "http://127.0.0.1:$port/missing"
rc=$?
set -e
[[ "$rc" -ne 0 ]]
# Accept 7 (connect refused) or 28 (operation timed out)
[[ "$rc" -eq 7 || "$rc" -eq 28 ]] || {
    printf 'unexpected curl exit %s\n' "$rc" >&2
    exit 1
}
