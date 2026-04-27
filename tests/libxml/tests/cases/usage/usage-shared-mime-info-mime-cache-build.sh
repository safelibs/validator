#!/usr/bin/env bash
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
validator_assert_contains "$tmpdir/globs2" "text/plain"
validator_assert_contains "$tmpdir/globs2" "application/xml"
