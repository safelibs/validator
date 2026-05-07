#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r14-ed-omit-decl-strips-prolog
# @title: xmlstarlet ed --omit-decl emits the edited document without the XML declaration
# @description: Edits an XML document with xmlstarlet ed --omit-decl plus an attribute update, captures stdout, and asserts the rewritten document carries the updated value but does NOT begin with the "<?xml" prolog that the same edit emits without --omit-decl.
# @timeout: 60
# @tags: usage, xmlstarlet, edit, omit-decl
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<config>
  <option name="mode" value="off"/>
</config>
XML

xmlstarlet ed --omit-decl \
    -u '/config/option[@name="mode"]/@value' -v 'on' \
    "$tmpdir/in.xml" >"$tmpdir/no-decl.out"
xmlstarlet ed \
    -u '/config/option[@name="mode"]/@value' -v 'on' \
    "$tmpdir/in.xml" >"$tmpdir/with-decl.out"

# --omit-decl must yield no XML prolog.
if grep -q '<?xml' "$tmpdir/no-decl.out"; then
    printf 'unexpected XML prolog under --omit-decl:\n' >&2
    cat "$tmpdir/no-decl.out" >&2
    exit 1
fi
# Default emit must include the XML prolog (sanity contrast).
grep -q '<?xml' "$tmpdir/with-decl.out" || {
    printf 'expected XML prolog without --omit-decl, got:\n' >&2
    cat "$tmpdir/with-decl.out" >&2
    exit 1
}

# The edit must still take effect in --omit-decl output.
validator_assert_contains "$tmpdir/no-decl.out" 'value="on"'
