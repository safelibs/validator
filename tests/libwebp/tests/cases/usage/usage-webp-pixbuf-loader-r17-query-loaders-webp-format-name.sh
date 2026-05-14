#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-r17-query-loaders-webp-format-name
# @title: gdk-pixbuf-query-loaders advertises the webp format with its descriptive name
# @description: Runs gdk-pixbuf-query-loaders, captures the cache, and asserts the listing contains the "WebP image" human-readable name field along with the bare 'webp' format token — exercising the pixbuf module manifest contributed by webp-pixbuf-loader.
# @timeout: 60
# @tags: usage, webp-pixbuf-loader, query-loaders
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

# The "WebP" descriptive name and the bare 'webp' token must both appear.
grep -Fq 'WebP' "$tmpdir/loaders.cache"
grep -Eq '"webp"' "$tmpdir/loaders.cache"
