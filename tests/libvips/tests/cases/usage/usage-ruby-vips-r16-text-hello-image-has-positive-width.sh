#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r16-text-hello-image-has-positive-width
# @title: ruby-vips Vips::Image.text renders 'Hello' into an image with positive width and height
# @description: Calls Vips::Image.text('Hello'), asserts the returned image has width and height greater than zero, bands equal to 1 (alpha mask), and that the mean across the image is strictly between 0 and 255, asserting libvips' Pango-backed text rasterizer emits a non-trivial alpha image.
# @timeout: 60
# @tags: usage, vips, ruby, text
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = Vips::Image.text("Hello")
raise "width=#{img.width}" unless img.width > 0
raise "height=#{img.height}" unless img.height > 0
raise "bands=#{img.bands}" unless img.bands == 1
m = img.avg
raise "avg out of range: #{m}" unless m > 0.0 && m < 255.0
puts "text avg=#{m} dims=#{img.width}x#{img.height}"
RUBY
