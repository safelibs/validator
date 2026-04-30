#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-svg-magic-detect
# @title: shared-mime-info SVG magic detect
# @description: Builds a private MIME database from the system shared-mime-info packages and verifies that a synthetic SVG payload is identified as image/svg+xml via the rebuilt globs2 plus magic data, exercising libxml2 SAX through update-mime-database.
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
validator_require_file "$tmpdir/magic"

validator_assert_contains "$tmpdir/globs2" ':image/svg+xml:*.svg'
validator_assert_contains "$tmpdir/magic" 'image/svg+xml'

mime_for_ext=$(awk -F: '$3=="*.svg" {print $2; exit}' "$tmpdir/globs2")
[[ "$mime_for_ext" == "image/svg+xml" ]] || {
  printf 'expected image/svg+xml glob for *.svg, got %s\n' "$mime_for_ext" >&2
  exit 1
}

magic_lines=$(grep -c '^\[[0-9]*:image/svg+xml\]$' "$tmpdir/magic" || true)
[[ "$magic_lines" -ge 1 ]] || {
  printf 'expected at least 1 svg magic block, got %s\n' "$magic_lines" >&2
  exit 1
}
