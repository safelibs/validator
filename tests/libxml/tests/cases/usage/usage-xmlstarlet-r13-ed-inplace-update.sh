#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r13-ed-inplace-update
# @title: xmlstarlet ed --inplace -u modifies the file on disk without writing to stdout
# @description: Writes a small XML document, runs xmlstarlet ed --inplace -u to update an attribute value in place, asserts the on-disk file now carries the new value while the original element structure is preserved and that no extra .bak file is produced when --inplace is used without a backup suffix.
# @timeout: 60
# @tags: usage, xmlstarlet, edit, inplace
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<config>
  <option name="mode" value="off"/>
</config>
XML

# Run --inplace: must NOT print to stdout, must rewrite the file.
xmlstarlet ed --inplace \
    -u '/config/option[@name="mode"]/@value' -v 'on' \
    "$tmpdir/in.xml" >"$tmpdir/stdout.log"

# stdout must be empty when --inplace is used.
[[ ! -s "$tmpdir/stdout.log" ]] || {
    printf 'expected empty stdout under --inplace, got:\n' >&2
    cat "$tmpdir/stdout.log" >&2
    exit 1
}

new_value=$(xmlstarlet sel -t -v 'string(/config/option/@value)' "$tmpdir/in.xml")
[[ "$new_value" == "on" ]] || {
    printf 'expected updated value "on", got %q\n' "$new_value" >&2
    cat "$tmpdir/in.xml" >&2
    exit 1
}

# No automatic backup file should be created.
[[ ! -e "$tmpdir/in.xml.bak" ]] || {
    printf 'unexpected backup file produced: in.xml.bak\n' >&2
    exit 1
}
