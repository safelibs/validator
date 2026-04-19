#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips -e "image=Vips::Image.black(16,12,bands:3); image.write_to_file(ARGV[0]); puts \"size=#{image.width}x#{image.height}\"" "$tmpdir/out.png"