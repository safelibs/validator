#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r9-extract-band-channel
# @title: ruby-vips extract_band selects single channel
# @description: Builds a 3-band RGB image with distinct values per band and extracts band 1 (green) using extract_band, asserting bands becomes 1 and the pixel equals the green component.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - <<'RUBY'
img = Vips::Image.black(8, 8, bands: 3) + [11, 77, 33]
img = img.cast(:uchar)
green = img.extract_band(1)
raise "bands #{green.bands}" unless green.bands == 1
raise "px #{green.getpoint(4, 4)}" unless green.getpoint(4, 4) == [77.0]
raise "max #{green.max}" unless green.max == 77.0
RUBY
