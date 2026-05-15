#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-r19-query-loaders-webp-extension-listed
# @title: gdk-pixbuf-query-loaders advertises the .webp file extension under webp-pixbuf-loader
# @description: Runs gdk-pixbuf-query-loaders and asserts the produced loader cache mentions the bare 'webp' token paired with the image/webp MIME, confirming the webp-pixbuf-loader registers its extension and MIME together.
# @timeout: 60
# @tags: usage, webp-pixbuf-loader, query-loaders, extension, r19
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
# The extension list block must contain 'webp' as a token entry.
grep -Eq '"webp"' "$tmpdir/loaders.cache" || {
    echo "expected the 'webp' extension token in loader cache" >&2
    sed -n '1,60p' "$tmpdir/loaders.cache" >&2
    exit 1
}
