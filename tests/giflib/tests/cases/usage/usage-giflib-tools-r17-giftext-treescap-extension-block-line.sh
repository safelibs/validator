#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r17-giftext-treescap-extension-block-line
# @title: giftext -e on treescap.gif reports at least one extension block line
# @description: Runs giftext -e on treescap.gif and asserts the report contains at least one "Ext Code = " line by counting matching lines and requiring the count to be greater than or equal to one, exercising the extension-block enumeration on a non-interlaced fixture.
# @timeout: 60
# @tags: usage, cli, giftext, extensions
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftext -e "$gif" >"$tmpdir/dump.txt"
count=$(grep -c 'Ext Code =' "$tmpdir/dump.txt" || true)
(( count >= 1 )) || {
    printf 'expected at least one Ext Code line, found %s\n' "$count" >&2
    sed -n '1,60p' "$tmpdir/dump.txt" >&2
    exit 1
}
