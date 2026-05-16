#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-r21-query-loaders-image-x-webp-mime
# @title: gdk-pixbuf-query-loaders output advertises an image/* webp MIME entry
# @description: Runs gdk-pixbuf-query-loaders, captures the cache, and asserts the cache mentions an image-class MIME entry referencing webp (image/webp or image/x-webp) — pinning webp-pixbuf-loader's GdkPixbuf MIME registration on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, webp-pixbuf-loader, query-loaders, mime, r21
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

grep -Eq '"image/(x-)?webp"' "$tmpdir/loaders.cache" || {
    echo "expected an image/webp or image/x-webp MIME entry" >&2
    sed -n '1,160p' "$tmpdir/loaders.cache" >&2
    exit 1
}
