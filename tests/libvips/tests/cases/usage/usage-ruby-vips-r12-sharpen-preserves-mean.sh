#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r12-sharpen-preserves-mean
# @title: ruby-vips Image#sharpen preserves the mean of a uniform LAB image
# @description: Builds an 8x8 sRGB constant image, converts to LAB-PQ format, applies Image#sharpen, converts back to sRGB and verifies the mean stays within 2 units of the original, asserting libvips' unsharp mask is mean-preserving on a uniform input.
# @timeout: 60
# @tags: usage, vips, ruby, sharpen, filter
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
band = (Vips::Image.black(8, 8) + 80).cast(:uchar)
rgb = band.bandjoin([band, band]).copy(interpretation: :srgb)
# vips sharpen wants a LabS image; convert explicitly with colourspace so
# ruby-vips on noble does not auto-route through the rejected multiband path.
labs = rgb.colourspace(:labs)
sharp_lab = labs.sharpen
sharp = sharp_lab.colourspace(:srgb)
diff = (sharp.avg - 80.0).abs
raise "sharpen mean drift=#{diff}" unless diff < 2.0
puts "sharpen avg=#{sharp.avg}"
RUBY
