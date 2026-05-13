#!/usr/bin/env bash
# @testcase: usage-gio-r16-mkdir-then-list-shows-entry
# @title: gio mkdir creates a directory that subsequently shows up under gio list
# @description: Runs gio mkdir against a fresh path inside a tmpdir, asserts the directory exists on disk, then runs gio list against the parent and confirms the newly-created basename appears verbatim in the listing output.
# @timeout: 60
# @tags: usage, gio, mkdir, list
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gio mkdir "$tmpdir/created-by-mkdir"
validator_require_dir "$tmpdir/created-by-mkdir"

gio list "$tmpdir" >"$tmpdir/listing.txt"
validator_assert_contains "$tmpdir/listing.txt" 'created-by-mkdir'
