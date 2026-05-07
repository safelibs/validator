#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-r14-query-loaders-extension-webp
# @title: gdk-pixbuf-query-loaders cache lists the .webp extension and 'webp' format name
# @description: Runs gdk-pixbuf-query-loaders and asserts the resulting loader cache contains both the bare 'webp' format token (loader name) and the explicit '.webp' or '"webp"' extension entry, confirming the loader is fully registered with gdk-pixbuf.
# @timeout: 180
# @tags: usage, webp, pixbuf
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

# Cache must contain the WebP MIME line and the WebP loader format token.
grep -q 'image/webp' "$tmpdir/loaders.cache"
grep -Eq '"webp"' "$tmpdir/loaders.cache"
