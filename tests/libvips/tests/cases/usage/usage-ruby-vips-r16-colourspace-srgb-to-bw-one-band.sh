#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r16-colourspace-srgb-to-bw-one-band
# @title: ruby-vips colourspace srgb to b_w reduces a 3-band image to a 1-band grayscale image
# @description: Builds a 6x6 three-band uchar image via bandjoin with constants (100, 150, 200), calls colourspace(:b_w, source_space: :srgb), and asserts the output image has bands 1 with 6x6 dimensions, exercising libvips' colour-space conversion from srgb to b_w (avoiding the unsupported :labs / :multiband routes).
# @timeout: 60
# @tags: usage, vips, ruby, colourspace
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
r = (Vips::Image.black(6, 6) + 100).cast(:uchar)
g = (Vips::Image.black(6, 6) + 150).cast(:uchar)
b = (Vips::Image.black(6, 6) + 200).cast(:uchar)
src = r.bandjoin([g, b])
raise "src bands=#{src.bands}" unless src.bands == 3

bw = src.colourspace(:b_w, source_space: :srgb)
raise "bw bands=#{bw.bands}" unless bw.bands == 1
raise "bw dims=#{bw.width}x#{bw.height}" unless bw.width == 6 && bw.height == 6
puts "colourspace bw bands=#{bw.bands}"
RUBY
