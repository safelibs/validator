#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-r10-thumbnailer-shows-image-webp
# @title: webp-pixbuf-loader registers a loadable .so at the expected GdkPixbuf loaders path
# @description: Verifies that the webp-pixbuf-loader package installs a loadable .so (libpixbufloader-webp.so) under /usr/lib/<triplet>/gdk-pixbuf-2.0/2.10.0/loaders and that the resulting loader cache (generated with gdk-pixbuf-query-loaders at its install-tree path) advertises the WebP extension. Covers the filesystem-level registration that the cache enumeration test does not.
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

# Filesystem-level registration: the loader .so must be present in the
# canonical loaders directory.
ls "$loaders_dir"/libpixbufloader-webp.so >/dev/null || {
    ls "$loaders_dir" >&2
    exit 1
}

# Locate gdk-pixbuf-query-loaders (libgdk-pixbuf2.0-bin installs it under
# /usr/lib/<triplet>/gdk-pixbuf-2.0/ on noble, not /usr/bin).
loader_query=""
for cand in gdk-pixbuf-query-loaders gdk-pixbuf-query-loaders-64; do
    if command -v "$cand" >/dev/null 2>&1; then
        loader_query=$cand; break
    fi
done
if [[ -z "$loader_query" ]]; then
    for path in /usr/lib/*/gdk-pixbuf-2.0/gdk-pixbuf-query-loaders \
                /usr/libexec/gdk-pixbuf-query-loaders; do
        if [[ -x "$path" ]]; then loader_query=$path; break; fi
    done
fi
[[ -n "$loader_query" ]] || { echo "gdk-pixbuf-query-loaders not found" >&2; exit 1; }

"$loader_query" "$loaders_dir"/*.so >"$tmpdir/cache.txt" 2>"$tmpdir/cache.err" || {
    sed -n '1,80p' "$tmpdir/cache.err" >&2
    exit 1
}

# The cache must list the webp extension (".webp" / "webp") for filename
# dispatch, distinguishing this from MIME-only sibling tests.
grep -Eq '"webp"' "$tmpdir/cache.txt"
