#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-r10-icon-element-types
# @title: shared-mime-info installs custom MIME with explicit icon element
# @description: Stages a synthetic MIME package that declares an explicit <icon> element on a custom mime-type, runs update-mime-database, and asserts the type is recorded in the generated types file along with a non-empty mime.cache.
# @timeout: 240
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

cat >"$tmpdir/packages/validator-icon.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-validator-iconed">
    <comment>Validator synthetic iconed type</comment>
    <icon name="text-x-generic-validator"/>
    <glob pattern="*.viconed"/>
  </mime-type>
</mime-info>
XML

update-mime-database "$tmpdir" >"$tmpdir/install.log" 2>&1 || {
  printf 'update-mime-database failed\n' >&2
  cat "$tmpdir/install.log" >&2
  exit 1
}

validator_require_file "$tmpdir/types"
validator_require_file "$tmpdir/mime.cache"
validator_require_file "$tmpdir/icons"

validator_assert_contains "$tmpdir/types" 'application/x-validator-iconed'
validator_assert_contains "$tmpdir/icons" 'application/x-validator-iconed:text-x-generic-validator'

# mime.cache must exist and be non-empty (its first 4 bytes are version).
size=$(wc -c <"$tmpdir/mime.cache")
[[ "$size" -gt 16 ]] || {
  printf 'mime.cache too small: %s bytes\n' "$size" >&2
  exit 1
}
