#!/usr/bin/env bash
# @testcase: usage-ruby-vips-histogram-image
# @title: ruby-vips histogram image
# @description: Builds an image histogram with ruby-vips and verifies populated histogram bins.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips <<'RUBY'
image = (Vips::Image.black(4, 4, bands: 1) + 7).cast("uchar")
histogram = image.hist_find
raise "unexpected histogram width: #{histogram.width}" unless histogram.width == 256

maximum = histogram.max
raise "empty histogram maximum: #{maximum}" unless maximum > 0

puts "histogram width=#{histogram.width} max=#{maximum}"
RUBY
