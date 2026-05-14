#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-r18-xdg-mime-detects-svg-image
# @title: xdg-mime query filetype identifies an SVG document as image/svg+xml
# @description: Writes a minimal SVG XML document and invokes xdg-mime query filetype (falling back to file --mime-type when xdg-mime is unavailable), then asserts the resolved type is image/svg+xml, exercising shared-mime-info's libxml-driven SVG detection rule.
# @timeout: 120
# @tags: usage, mime, svg, detect, r18
# @client: shared-mime-info

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/sample.svg" <<'SVG'
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10">
  <rect width="10" height="10" fill="#0a0"/>
</svg>
SVG

mime=""
if command -v xdg-mime >/dev/null 2>&1; then
    mime=$(xdg-mime query filetype "$tmpdir/sample.svg" 2>/dev/null || true)
fi
if [[ -z "$mime" ]] && command -v file >/dev/null 2>&1; then
    mime=$(file --mime-type -b "$tmpdir/sample.svg")
fi

[[ -n "$mime" ]] || { echo "could not determine MIME type" >&2; exit 1; }

case "$mime" in
    image/svg+xml|image/svg)
        ;;
    *)
        printf 'expected image/svg+xml, got %q\n' "$mime" >&2
        exit 1
        ;;
esac
