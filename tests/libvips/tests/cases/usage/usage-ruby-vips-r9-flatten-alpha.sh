#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r9-flatten-alpha
# @title: ruby-vips flatten removes alpha against background
# @description: Flattens an RGBA image with a fully transparent area against a red background and verifies the resulting RGB pixel matches the background colour.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - <<'RUBY'
rgb = Vips::Image.black(8, 8, bands: 3) + [10, 20, 30]
alpha = Vips::Image.black(8, 8, bands: 1) # alpha = 0 (fully transparent)
rgba = rgb.bandjoin(alpha).cast(:uchar)
raise "bands #{rgba.bands}" unless rgba.bands == 4
flat = rgba.flatten(background: [255, 0, 0])
raise "bands #{flat.bands}" unless flat.bands == 3
px = flat.getpoint(2, 3)
raise "got #{px.inspect}" unless px == [255.0, 0.0, 0.0]
RUBY
