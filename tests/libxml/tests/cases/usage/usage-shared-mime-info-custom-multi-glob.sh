#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-custom-multi-glob
# @title: shared-mime-info custom MIME with multiple globs
# @description: Stages a synthetic MIME package that defines a single application-defined type with three distinct glob patterns (suffix, prefix, and directory wildcard), runs update-mime-database to install it, then verifies that every glob is registered in globs2 and resolves back to the same MIME type, exercising libxml2 SAX parsing of multi-glob mime-type entries.
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

# Synthetic type with three globs.
cat >"$tmpdir/packages/validator-multi.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-validator-multi">
    <comment>Validator synthetic multi-glob document</comment>
    <glob pattern="*.vmulti"/>
    <glob pattern="*.vmx"/>
    <glob pattern="vmulti-*.dat"/>
  </mime-type>
</mime-info>
XML

update-mime-database "$tmpdir" >"$tmpdir/install.log" 2>&1 || {
  printf 'update-mime-database failed\n' >&2
  cat "$tmpdir/install.log" >&2
  exit 1
}

validator_require_file "$tmpdir/mime.cache"
validator_require_file "$tmpdir/globs2"
validator_require_file "$tmpdir/types"

# The synthetic MIME type itself must be registered.
validator_assert_contains "$tmpdir/types" 'application/x-validator-multi'

# Each glob pattern must resolve to the synthetic type.
for pattern in '*.vmulti' '*.vmx' 'vmulti-*.dat'; do
  hit=$(awk -F: -v want="$pattern" '$3 == want {print $2; exit}' "$tmpdir/globs2")
  [[ "$hit" == "application/x-validator-multi" ]] || {
    printf 'glob %s -> expected application/x-validator-multi, got %q\n' "$pattern" "$hit" >&2
    grep -F "$pattern" "$tmpdir/globs2" >&2 || true
    exit 1
  }
done

# Total count of glob lines for this MIME type must be exactly 3.
glob_count=$(grep -c ':application/x-validator-multi:' "$tmpdir/globs2" || true)
[[ "$glob_count" == "3" ]] || {
  printf 'expected 3 globs for synthetic type, got %s\n' "$glob_count" >&2
  grep ':application/x-validator-multi:' "$tmpdir/globs2" >&2 || true
  exit 1
}

printf 'mime-type=application/x-validator-multi\n'
printf 'glob-count=%s\n' "$glob_count"
