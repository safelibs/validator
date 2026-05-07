#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r15-invert-uchar-30-becomes-225
# @title: ruby-vips Image#invert maps a flat uchar 30 image to a flat 225 image
# @description: Builds a 4x4 single-band uchar image with constant 30, applies Vips::Image#invert, and verifies the result has the same dimensions, bands == 1, and an average of 225.0 (i.e. 255 - 30), asserting libvips' invert performs the per-pixel uchar two's-complement-style negation 255 - x.
# @timeout: 60
# @tags: usage, vips, ruby, invert
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(4, 4) + 30).cast(:uchar)
inv = src.invert
raise "invert dims=#{inv.width}x#{inv.height}" unless inv.width == 4 && inv.height == 4
raise "invert bands=#{inv.bands}" unless inv.bands == 1
raise "invert avg=#{inv.avg}" unless inv.avg == 225.0
puts "invert(30) avg=#{inv.avg}"
RUBY
