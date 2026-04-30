#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-rss-atom-globs
# @title: shared-mime-info RSS and Atom globs
# @description: Rebuilds the shared-mime-info database and verifies that XML-derived feed types (application/rss+xml and application/atom+xml) appear in the generated globs2 and types files with the expected extensions, exercising libxml2 parsing of MIME packages.
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

validator_assert_contains "$tmpdir/globs2" ':application/rss+xml:*.rss'
validator_assert_contains "$tmpdir/globs2" ':application/atom+xml:*.atom'
validator_assert_contains "$tmpdir/types" 'application/rss+xml'
validator_assert_contains "$tmpdir/types" 'application/atom+xml'

rss_glob_count=$(grep -c ':application/rss+xml:' "$tmpdir/globs2" || true)
atom_glob_count=$(grep -c ':application/atom+xml:' "$tmpdir/globs2" || true)

[[ "$rss_glob_count" -ge 1 ]] || {
  printf 'expected at least 1 rss glob, got %s\n' "$rss_glob_count" >&2
  exit 1
}
[[ "$atom_glob_count" -ge 1 ]] || {
  printf 'expected at least 1 atom glob, got %s\n' "$atom_glob_count" >&2
  exit 1
}
