#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-query-loaders-includes-webp
# @title: gdk-pixbuf-query-loaders includes WebP
# @description: Runs gdk-pixbuf-query-loaders and verifies the WebP pixbuf loader is registered, decoding the loader cache for the WebP MIME type and image/webp entry.
# @timeout: 180
# @tags: usage, webp, pixbuf
# @client: webp-pixbuf-loader

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# gdk-pixbuf ships the query tool under different names depending on the version.
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
if [[ -z "$loader_query" ]]; then
  echo "gdk-pixbuf-query-loaders not found" >&2
  exit 1
fi

"$loader_query" >"$tmpdir/loaders.cache"
validator_require_file "$tmpdir/loaders.cache"
test -s "$tmpdir/loaders.cache"

# The loader cache lists registered MIME types and extensions. The WebP pixbuf
# loader must publish image/webp and the .webp extension.
validator_assert_contains "$tmpdir/loaders.cache" 'image/webp'
validator_assert_contains "$tmpdir/loaders.cache" 'webp'

# Sanity check: the cache must include at least one loader entry header.
grep -Eq '^"' "$tmpdir/loaders.cache"
