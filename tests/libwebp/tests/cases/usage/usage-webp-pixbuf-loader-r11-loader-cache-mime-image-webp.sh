#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-r11-loader-cache-mime-image-webp
# @title: webp-pixbuf-loader registers the image/webp MIME type in loaders.cache
# @description: Reads the system gdk-pixbuf loaders.cache and asserts a libpixbufloader-webp.so block is present and that the same record advertises the image/webp MIME type and the .webp extension token.
# @timeout: 60
# @tags: usage, webp-pixbuf-loader, webp
# @client: webp-pixbuf-loader

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

loaders_cache="/usr/lib/$(validator_multiarch)/gdk-pixbuf-2.0/2.10.0/loaders.cache"
validator_require_file "$loaders_cache"

# The cache must reference the webp loader shared object.
grep -q 'libpixbufloader-webp\.so' "$loaders_cache"

# The webp loader block must list image/webp as a supported MIME type and
# include an extension token. Print just the four lines after the loader
# header and assert both invariants on that slice.
awk '
  /libpixbufloader-webp\.so/ {found=1; lines=4; next}
  found && lines>0 {print; lines--}
' "$loaders_cache" >/tmp/.webp-loader-block.$$
trap 'rm -f /tmp/.webp-loader-block.'$$ EXIT

grep -Fq '"image/webp"' /tmp/.webp-loader-block.$$
grep -Fq '"webp"' /tmp/.webp-loader-block.$$
