#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-r10-thumbnailer-shows-image-webp
# @title: GdkPixbuf query-loaders advertises the image/webp MIME type
# @description: Runs gdk-pixbuf-query-loaders against the system loader cache and asserts the output advertises the image/webp MIME type, proving the webp-pixbuf-loader package is registered with gdk-pixbuf.
# @timeout: 60
# @tags: usage, webp-pixbuf-loader, webp
# @client: webp-pixbuf-loader

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

triplet=$(gcc -print-multiarch)
loaders_dir="/usr/lib/${triplet}/gdk-pixbuf-2.0/2.10.0/loaders"
validator_require_dir "$loaders_dir"

gdk-pixbuf-query-loaders "$loaders_dir"/*.so >"$tmpdir/cache.txt" 2>"$tmpdir/cache.err" || {
    sed -n '1,80p' "$tmpdir/cache.err" >&2
    exit 1
}

grep -q '"image/webp"' "$tmpdir/cache.txt"
grep -Eqi '(WebP|webp)' "$tmpdir/cache.txt"
