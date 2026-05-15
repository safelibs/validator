#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-r20-query-loaders-libpixbufloader-webp-path
# @title: gdk-pixbuf-query-loaders cache references a libpixbufloader-webp module path
# @description: Runs gdk-pixbuf-query-loaders and asserts the cache lists a module path matching libpixbufloader-webp.so (the shared object that ships in the webp-pixbuf-loader package), pinning the GdkPixbuf loader discovery for libwebp on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, webp-pixbuf-loader, query-loaders, module-path, r20
# @client: webp-pixbuf-loader

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

loader_query=""
for cand in gdk-pixbuf-query-loaders gdk-pixbuf-query-loaders-64; do
  if command -v "$cand" >/dev/null 2>&1; then
    loader_query=$cand
    break
  fi
done
if [[ -z "$loader_query" ]]; then
  for path in /usr/lib/*/gdk-pixbuf-2.0/gdk-pixbuf-query-loaders \
              /usr/libexec/gdk-pixbuf-query-loaders; do
    if [[ -x "$path" ]]; then
      loader_query=$path
      break
    fi
  done
fi
[[ -n "$loader_query" ]] || { echo "gdk-pixbuf-query-loaders not found" >&2; exit 1; }

"$loader_query" >"$tmpdir/loaders.cache"
[[ -s "$tmpdir/loaders.cache" ]]

grep -Eq 'libpixbufloader-webp\.so' "$tmpdir/loaders.cache" || {
    echo "expected libpixbufloader-webp.so module path in cache" >&2
    sed -n '1,120p' "$tmpdir/loaders.cache" >&2
    exit 1
}
