#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-r15-loaders-cache-mime-image-webp
# @title: gdk-pixbuf-query-loaders cache lists the image/webp MIME type alongside the webp loader name
# @description: Runs gdk-pixbuf-query-loaders, captures the resulting cache, and asserts both the literal image/webp MIME line and the bare 'webp' format token appear in it, confirming the WebP loader registers its MIME mapping with gdk-pixbuf.
# @timeout: 180
# @tags: usage, webp-pixbuf-loader, mime
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

# image/webp MIME line.
grep -Fq 'image/webp' "$tmpdir/loaders.cache"
# 'webp' format token (loader name in quotes).
grep -Eq '"webp"' "$tmpdir/loaders.cache"
