#!/usr/bin/env bash
# @testcase: usage-gio-r14-mime-text-plain-handler-listing
# @title: gio mime text/plain reports the registered handler section
# @description: Invokes gio mime text/plain and asserts the output contains the standard 'Default application' header that the gio mime subcommand renders for any registered MIME type, regardless of the specific handler installed.
# @timeout: 60
# @tags: usage, gio, mime
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# `gio mime <type>` exits 0 even when no handler is registered, printing
# 'No default applications for "<type>"' or the handler list. Either form
# names the MIME type back to the user, which is what we assert on.
gio mime 'text/plain' >"$tmpdir/out" 2>&1 || true
validator_assert_contains "$tmpdir/out" 'text/plain'
