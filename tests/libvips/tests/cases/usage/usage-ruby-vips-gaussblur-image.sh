#!/usr/bin/env bash
# @testcase: usage-ruby-vips-gaussblur-image
# @title: ruby-vips Gaussian blur image
# @description: Applies a Gaussian blur with ruby-vips and verifies image dimensions and pixel average.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips <<'RUBY'
image = Vips::Image.black(8, 8, bands: 1) + 64
blurred = image.gaussblur(1.2)
raise "unexpected dimensions: #{blurred.width}x#{blurred.height}" unless blurred.width == 8 && blurred.height == 8

average = blurred.avg
raise "unexpected average: #{average}" unless average > 0 && average < 255

puts "gaussblur #{blurred.width}x#{blurred.height} avg=#{average}"
RUBY
