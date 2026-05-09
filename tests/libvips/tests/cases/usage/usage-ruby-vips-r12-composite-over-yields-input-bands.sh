#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r12-composite-over-yields-input-bands
# @title: ruby-vips Image#composite2 over preserves the base image dimensions and bands
# @description: Builds two 16x16 RGBA uchar images and verifies base.composite2(top, :over) yields an output of the same width, height, and 4 bands, asserting libvips' default 'over' alpha compositor returns a buffer matching the base layer's geometry.
# @timeout: 60
# @tags: usage, vips, ruby, composite
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
def rgba_image(w, h, r, g, b, a)
  band = ->(v) { (Vips::Image.black(w, h) + v).cast(:uchar) }
  rgba = band[r].bandjoin([band[g], band[b], band[a]])
  # Tag the buffer as sRGB so composite2 does not try to auto-convert from a
  # multiband/Lab interpretation that ruby-vips rejects on noble.
  rgba.copy(interpretation: :srgb)
end

base = rgba_image(16, 16, 200, 50, 50, 255)
top  = rgba_image(16, 16, 50, 200, 50, 128)
out = base.composite2(top, :over, compositing_space: :srgb)
raise "composite dims=#{out.width}x#{out.height}" unless out.width == 16 && out.height == 16
raise "composite bands=#{out.bands}" unless out.bands == 4
puts "composite2 over dims=#{out.width}x#{out.height} bands=#{out.bands}"
RUBY
