#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r21-composite2-over-mode-bands
# @title: ruby-vips Image#composite2 :over preserves the input band count after compositing two RGBA images
# @description: Builds two 6x6 4-band uchar images (RGBA), tags them as sRGB with alpha via colourspace conversion, calls bottom.composite2(top, :over), and asserts the output has the same width, height, and bands as the bottom layer, exercising libvips' alpha-aware compositing.
# @timeout: 60
# @tags: usage, vips, ruby, composite, r21
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
base = (Vips::Image.black(6, 6) + 30).cast(:uchar)
bottom = base.bandjoin([base, base, Vips::Image.black(6, 6).cast(:uchar) + 255]).copy(interpretation: :srgb)
top    = base.bandjoin([base, base, Vips::Image.black(6, 6).cast(:uchar) + 128]).copy(interpretation: :srgb)
raise "bands_b=#{bottom.bands}" unless bottom.bands == 4
out = bottom.composite2(top, :over)
raise "out_w=#{out.width}" unless out.width == bottom.width
raise "out_h=#{out.height}" unless out.height == bottom.height
raise "out_bands=#{out.bands}" unless out.bands == bottom.bands
puts "composite2 over bands=#{out.bands}"
RUBY
