#!/usr/bin/env bash
# @testcase: usage-curl-disallow-username-in-url
# @title: curl --disallow-username-in-url rejects creds in URL
# @description: Invokes curl with --disallow-username-in-url against a URL that embeds user credentials and expects curl to fail with a non-zero exit and a 'rejected' diagnostic, leaving the loopback server untouched.
# @timeout: 60
# @tags: usage, curl, security
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-disallow-username-in-url"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

set +e
curl -sS --disallow-username-in-url "http://alice@127.0.0.1:1/x" >"$tmpdir/out" 2>"$tmpdir/err"
rc=$?
set -e
[[ $rc -ne 0 ]]
# The diagnostic mentions credentials/URL rejection.
grep -Eqi 'rejected|credential|username' "$tmpdir/err"
