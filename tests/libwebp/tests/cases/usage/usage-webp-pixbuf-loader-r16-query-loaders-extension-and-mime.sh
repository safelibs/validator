#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-r16-query-loaders-extension-and-mime
# @title: gdk-pixbuf-query-loaders cache pairs the webp extension with the image/webp MIME entry
# @description: Runs gdk-pixbuf-query-loaders, captures the cache, and asserts the output simultaneously contains the bare 'webp' format token, the 'image/webp' MIME line, and a quoted '.webp' extension/glob entry — locking in extension + MIME registration of the WebP gdk-pixbuf loader.
# @timeout: 120
# @tags: usage, webp-pixbuf-loader, mime, extension
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
grep -Eq '"webp"' "$tmpdir/loaders.cache"
grep -Eq '"\.?webp"' "$tmpdir/loaders.cache"
