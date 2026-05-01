#!/usr/bin/env bash
# @testcase: usage-exif-cli-help-option-banner
# @title: exif --help lists every documented switch
# @description: Runs exif --help and verifies the help screen advertises the canonical option set including --tag, --ifd, --list-tags, --show-mnote, --remove, --extract-thumbnail, --insert-thumbnail, --no-fixup, --output, --set-value, --create-exif, --machine-readable, --width, --xml-output, and --debug, exactly as shipped on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-help-option-banner"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

exif --help >"$tmpdir/out" 2>&1

validator_assert_contains "$tmpdir/out" 'Usage: exif [OPTION...] file'
validator_assert_contains "$tmpdir/out" '-v, --version'
validator_assert_contains "$tmpdir/out" '-i, --ids'
validator_assert_contains "$tmpdir/out" '-t, --tag=tag'
validator_assert_contains "$tmpdir/out" '--ifd=IFD'
validator_assert_contains "$tmpdir/out" '-l, --list-tags'
validator_assert_contains "$tmpdir/out" '--show-mnote'
validator_assert_contains "$tmpdir/out" '--remove'
validator_assert_contains "$tmpdir/out" '-s, --show-description'
validator_assert_contains "$tmpdir/out" '-e, --extract-thumbnail'
validator_assert_contains "$tmpdir/out" '-r, --remove-thumbnail'
validator_assert_contains "$tmpdir/out" '-n, --insert-thumbnail=FILE'
validator_assert_contains "$tmpdir/out" '--no-fixup'
validator_assert_contains "$tmpdir/out" '-o, --output=FILE'
validator_assert_contains "$tmpdir/out" '--set-value=STRING'
validator_assert_contains "$tmpdir/out" '-c, --create-exif'
validator_assert_contains "$tmpdir/out" '-m, --machine-readable'
validator_assert_contains "$tmpdir/out" '-w, --width=WIDTH'
validator_assert_contains "$tmpdir/out" '-x, --xml-output'
validator_assert_contains "$tmpdir/out" '-d, --debug'
validator_assert_contains "$tmpdir/out" 'Help options:'
validator_assert_contains "$tmpdir/out" '-?, --help'
validator_assert_contains "$tmpdir/out" '--usage'
