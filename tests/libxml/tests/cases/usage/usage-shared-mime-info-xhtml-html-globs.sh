#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-xhtml-html-globs
# @title: shared-mime-info xhtml and html globs
# @description: Rebuilds the shared-mime-info database from the system MIME packages and verifies that application/xhtml+xml and text/html types appear with their canonical extensions in globs2 plus a text/html magic block, exercising libxml2 SAX through update-mime-database.
# @timeout: 180
# @tags: usage, xml, mime
# @client: shared-mime-info

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

mime_packages_src=/usr/share/mime/packages
validator_require_dir "$mime_packages_src"
validator_require_file "$mime_packages_src/freedesktop.org.xml"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/packages"
cp "$mime_packages_src"/*.xml "$tmpdir/packages/"

update-mime-database "$tmpdir"

validator_require_file "$tmpdir/mime.cache"
validator_require_file "$tmpdir/globs2"
validator_require_file "$tmpdir/types"
validator_require_file "$tmpdir/magic"

validator_assert_contains "$tmpdir/globs2" ':application/xhtml+xml:*.xhtml'
validator_assert_contains "$tmpdir/globs2" ':text/html:*.html'
validator_assert_contains "$tmpdir/types"  'application/xhtml+xml'
validator_assert_contains "$tmpdir/types"  'text/html'

xhtml_mime=$(awk -F: '$3=="*.xhtml" {print $2; exit}' "$tmpdir/globs2")
[[ "$xhtml_mime" == "application/xhtml+xml" ]] || {
  printf 'expected application/xhtml+xml for *.xhtml, got %s\n' "$xhtml_mime" >&2
  exit 1
}

html_mime=$(awk -F: '$3=="*.html" {print $2; exit}' "$tmpdir/globs2")
[[ "$html_mime" == "text/html" ]] || {
  printf 'expected text/html for *.html, got %s\n' "$html_mime" >&2
  exit 1
}

html_magic=$(grep -c '^\[[0-9]*:text/html\]$' "$tmpdir/magic" || true)
[[ "$html_magic" -ge 1 ]] || {
  printf 'expected at least 1 text/html magic block, got %s\n' "$html_magic" >&2
  exit 1
}
