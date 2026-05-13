#!/usr/bin/env bash
# @testcase: usage-curl-r16-file-url-md5-equal
# @title: curl file:// fetches a local file byte-identical to its source
# @description: Builds a small binary payload and asserts curl with a file:// URL produces output whose sha256 equals the source file's sha256, exercising curl's filesystem-source path without involving any network or HTTP server.
# @timeout: 30
# @tags: usage, curl, file-url, hash
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "import sys; sys.stdout.buffer.write(bytes(range(256))*4)" >"$tmpdir/src.bin"
expected=$(sha256sum "$tmpdir/src.bin" | awk '{print $1}')

curl -fsS --max-time 5 "file://$tmpdir/src.bin" -o "$tmpdir/dst.bin"
got=$(sha256sum "$tmpdir/dst.bin" | awk '{print $1}')
[[ "$expected" == "$got" ]]
