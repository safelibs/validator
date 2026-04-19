#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips -e "image=Vips::Image.black(20,10,bands:3); out=image.crop(1,1,5,4); puts \"crop=#{out.width}x#{out.height}\"" "$tmpdir/out.png"