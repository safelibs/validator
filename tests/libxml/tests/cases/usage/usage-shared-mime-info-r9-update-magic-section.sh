#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-r9-update-magic-section
# @title: shared-mime-info update writes a magic file
# @description: Rebuilds the shared-mime-info database from /usr/share/mime/packages into a temp prefix and verifies that mime.cache, magic, and globs are produced.
# @timeout: 180
# @tags: usage, xml, mime
# @client: shared-mime-info

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

mime_packages_src=/usr/share/mime/packages
validator_require_dir "$mime_packages_src"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/packages"
cp "$mime_packages_src"/*.xml "$tmpdir/packages/"

update-mime-database "$tmpdir" 2>"$tmpdir/update.err" || {
  cat "$tmpdir/update.err" >&2
  exit 1
}

validator_require_file "$tmpdir/mime.cache"
validator_require_file "$tmpdir/magic"
validator_require_file "$tmpdir/globs"

# magic file uses the documented "MIME-Magic\0\n" header.
head -c 12 "$tmpdir/magic" >"$tmpdir/magic.head"
grep -q 'MIME-Magic' "$tmpdir/magic.head" || {
  echo "magic header missing" >&2
  od -c "$tmpdir/magic.head" >&2
  exit 1
}

# globs format is "mime/type:glob-pattern"; require at least one universal entry.
grep -Eq '^(text/plain|application/xml):' "$tmpdir/globs"
