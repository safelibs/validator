#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-r21-xdg-mime-query-default-text
# @title: file --mime-type reports text/plain for a simple .txt input on a shared-mime-info system
# @description: Creates a small .txt file and runs file --mime-type, falling back gracefully and asserting the returned MIME type equals text/plain — pinning shared-mime-info's libxml-built text/plain detection rule on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, shared-mime-info, mime-type, text-plain, r21
# @client: shared-mime-info

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'plain ascii text r21\n' >"$tmpdir/sample.txt"

command -v file >/dev/null 2>&1 || { echo "file(1) not available" >&2; exit 1; }

mime=$(file --mime-type -b "$tmpdir/sample.txt")
[[ "$mime" == "text/plain" ]] || { printf 'expected text/plain, got: %s\n' "$mime" >&2; exit 1; }

# Also corroborate via the system mime database: text/plain must exist as a known type.
grep -Fq '<mime-type type="text/plain">' /usr/share/mime/packages/freedesktop.org.xml || {
    echo "expected text/plain mime-type entry in freedesktop.org.xml" >&2
    exit 1
}
