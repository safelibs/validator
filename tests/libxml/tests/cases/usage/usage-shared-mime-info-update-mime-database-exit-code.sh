#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-update-mime-database-exit-code
# @title: shared-mime-info update-mime-database exit code
# @description: Builds a private MIME database from the system shared-mime-info packages, asserts update-mime-database exits with status 0, then runs it again pointing at a directory with no packages subdirectory and verifies it exits non-zero, exercising libxml2 SAX through update-mime-database error and success paths.
# @timeout: 180
# @tags: usage, xml, mime, exit-code
# @client: shared-mime-info

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

mime_packages_src=/usr/share/mime/packages
validator_require_dir "$mime_packages_src"
validator_require_file "$mime_packages_src/freedesktop.org.xml"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/good/packages"
cp "$mime_packages_src"/*.xml "$tmpdir/good/packages/"

set +e
update-mime-database "$tmpdir/good" >"$tmpdir/good-out" 2>&1
good_status=$?
set -e

[[ "$good_status" -eq 0 ]] || {
  printf 'expected update-mime-database to succeed, got status %s\n' "$good_status" >&2
  cat "$tmpdir/good-out" >&2
  exit 1
}

validator_require_file "$tmpdir/good/mime.cache"
validator_require_file "$tmpdir/good/globs2"
validator_require_file "$tmpdir/good/types"

mkdir -p "$tmpdir/bad"

set +e
update-mime-database "$tmpdir/bad" >"$tmpdir/bad-out" 2>&1
bad_status=$?
set -e

[[ "$bad_status" -ne 0 ]] || {
  printf 'expected non-zero exit when packages dir is missing, got %s\n' "$bad_status" >&2
  cat "$tmpdir/bad-out" >&2
  exit 1
}

if [[ -f "$tmpdir/bad/mime.cache" ]]; then
  printf 'expected no mime.cache to be produced for bad input\n' >&2
  exit 1
fi

printf 'good-status=%s\nbad-status=%s\n' "$good_status" "$bad_status"
