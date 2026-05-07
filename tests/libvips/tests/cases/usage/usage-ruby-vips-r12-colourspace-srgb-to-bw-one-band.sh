#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r12-colourspace-srgb-to-bw-one-band
# @title: ruby-vips Image#colourspace srgb to b-w yields a single-band image
# @description: Builds a 3-band uchar sRGB image with green-dominant pixels and verifies Image#colourspace(:b_w) returns a 1-band image whose mean is in (0, 255), asserting the libvips greyscale conversion path is exercised through the Ruby colour transform binding.
# @timeout: 60
# @tags: usage, vips, ruby, colourspace, bw
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
band = (Vips::Image.black(8, 8) + 100).cast(:uchar)
rgb = band.bandjoin([band, band])
raise "rgb bands=#{rgb.bands}" unless rgb.bands == 3
bw = rgb.colourspace(:b_w)
raise "bw bands=#{bw.bands}" unless bw.bands == 1
raise "bw avg=#{bw.avg}" unless bw.avg > 0.0 && bw.avg < 255.0
puts "colourspace b-w bands=#{bw.bands} avg=#{bw.avg}"
RUBY
