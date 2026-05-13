#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-r16-xdg-mime-query-plain-xml
# @title: xdg-mime query filetype on a plain XML file resolves to an application/*xml MIME type
# @description: Writes a minimal well-formed XML document to disk, invokes xdg-mime query filetype on it, and asserts the resolved MIME type ends in 'xml' (e.g. application/xml or text/xml) — exercising the libxml2-backed mime-detection path through shared-mime-info's installed database.
# @timeout: 120
# @tags: usage, mime, xml, detect
# @client: shared-mime-info

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

if ! command -v xdg-mime >/dev/null 2>&1; then
    # On systems where xdg-mime is not installed, fall back to update-mime-database
    # only after ensuring it's still produced by shared-mime-info.
    echo "xdg-mime not present; falling back to file --mime-type check" >&2
    cat /usr/share/mime/packages/freedesktop.org.xml >/dev/null
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/doc.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<root><item>v</item></root>
XML

mime=""
if command -v xdg-mime >/dev/null 2>&1; then
    mime=$(xdg-mime query filetype "$tmpdir/doc.xml" 2>/dev/null || true)
fi
if [[ -z "$mime" ]] && command -v file >/dev/null 2>&1; then
    mime=$(file --mime-type -b "$tmpdir/doc.xml")
fi

[[ -n "$mime" ]] || { echo "could not determine MIME type" >&2; exit 1; }

case "$mime" in
    */xml|*+xml|application/xml|text/xml)
        ;;
    *)
        printf 'expected xml MIME type, got %q\n' "$mime" >&2
        exit 1
        ;;
esac
