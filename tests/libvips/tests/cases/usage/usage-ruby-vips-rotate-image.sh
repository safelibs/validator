#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips -e "image=Vips::Image.black(5,9,bands:3); out=image.rot90; puts \"rot=#{out.width}x#{out.height}\"" "$tmpdir/out.png"