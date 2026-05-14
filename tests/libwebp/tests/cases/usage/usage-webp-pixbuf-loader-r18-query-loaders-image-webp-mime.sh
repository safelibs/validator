#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-r18-query-loaders-image-webp-mime
# @title: gdk-pixbuf-query-loaders lists image/webp as a registered MIME type
# @description: Invokes gdk-pixbuf-query-loaders and asserts the resulting loader manifest contains the image/webp MIME entry contributed by webp-pixbuf-loader, evidencing libwebp-backed loader registration.
# @timeout: 60
# @tags: usage, webp-pixbuf-loader, query-loaders, mime, r18
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
grep -Fq 'image/webp' "$tmpdir/loaders.cache"
