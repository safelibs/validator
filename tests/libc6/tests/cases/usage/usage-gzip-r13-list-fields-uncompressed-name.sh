#!/usr/bin/env bash
# @testcase: usage-gzip-r13-list-fields-uncompressed-name
# @title: gzip -l listing exposes header columns and the uncompressed filename
# @description: Compresses a known payload with gzip -k, runs gzip -l on the resulting .gz, and asserts both that the header row carries the expected column labels and that the data row references the uncompressed source name.
# @timeout: 60
# @tags: usage, gzip, listing
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

LC_ALL=C printf 'r13 gzip listing payload line %d\n' {1..32} >"$tmpdir/payload.txt"

LC_ALL=C gzip -k -n "$tmpdir/payload.txt"
[[ -s "$tmpdir/payload.txt.gz" ]]

LC_ALL=C gzip -l "$tmpdir/payload.txt.gz" >"$tmpdir/listing.txt"

# Header row carries the documented column labels.
validator_assert_contains "$tmpdir/listing.txt" 'compressed'
validator_assert_contains "$tmpdir/listing.txt" 'uncompressed'
validator_assert_contains "$tmpdir/listing.txt" 'ratio'
# Data row references the uncompressed source filename.
validator_assert_contains "$tmpdir/listing.txt" 'payload.txt'
