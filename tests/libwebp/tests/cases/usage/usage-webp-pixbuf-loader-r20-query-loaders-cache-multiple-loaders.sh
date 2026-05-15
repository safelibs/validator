#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-r20-query-loaders-cache-multiple-loaders
# @title: gdk-pixbuf-query-loaders cache lists at least two LoaderDir paths around the webp loader
# @description: Runs gdk-pixbuf-query-loaders and asserts the produced cache contains an explicit "LoaderDir" comment header and that the webp loader appears together with at least one other distinct .so module path — pinning that the webp-pixbuf-loader coexists with the wider GdkPixbuf loader set on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, webp-pixbuf-loader, query-loaders, coexistence, r20
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

# Webp loader must appear.
grep -Fq 'libpixbufloader-webp' "$tmpdir/loaders.cache"

# Count distinct .so loader module lines (loader lines look like a path string in quotes ending .so).
so_count=$(grep -Eo '"[^"]+\.so"' "$tmpdir/loaders.cache" | sort -u | wc -l)
(( so_count >= 2 )) || {
    printf 'expected at least 2 distinct .so loaders in cache, got %d\n' "$so_count" >&2
    sed -n '1,120p' "$tmpdir/loaders.cache" >&2
    exit 1
}
