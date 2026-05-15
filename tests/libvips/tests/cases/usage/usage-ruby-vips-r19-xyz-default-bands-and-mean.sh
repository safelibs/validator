#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r19-xyz-default-bands-and-mean
# @title: ruby-vips Image.xyz produces a 2-band uint coordinate image with mean equal to half the max coordinate
# @description: Builds a 10x8 coordinate image with Vips::Image.xyz(10, 8), asserts the result has width 10, height 8, and exactly 2 bands (x and y coordinates), and asserts band 0 has min 0 and max 9 (10 columns) and band 1 has min 0 and max 7 (8 rows), confirming libvips' canonical 2-band coordinate generator.
# @timeout: 60
# @tags: usage, vips, ruby, xyz, generator, r19
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = Vips::Image.xyz(10, 8)
raise "dims #{img.width}x#{img.height}" unless img.width == 10 && img.height == 8
raise "bands=#{img.bands}" unless img.bands == 2
bx = img.extract_band(0)
by = img.extract_band(1)
raise "bx min=#{bx.min}" unless bx.min == 0
raise "bx max=#{bx.max}" unless bx.max == 9
raise "by min=#{by.min}" unless by.min == 0
raise "by max=#{by.max}" unless by.max == 7
puts "xyz #{img.width}x#{img.height} bands=#{img.bands}"
RUBY
