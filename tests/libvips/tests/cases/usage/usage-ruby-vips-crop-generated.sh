#!/usr/bin/env bash
# @testcase: usage-ruby-vips-crop-generated
# @title: ruby-vips crop generated image
# @description: Exercises ruby-vips crop generated image through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-crop-generated"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]

def gray_image(width, height, pixels)
  Vips::Image.new_from_memory(pixels.pack('C*'), width, height, 1, :uchar)
end

def multiband_image(width, height, bands, pixels)
  Vips::Image.new_from_memory(pixels.pack('C*'), width, height, bands, :uchar)
end

def gray_pixel(image, x, y)
  image.extract_area(x, y, 1, 1).write_to_memory.bytes[0]
end

image = gray_image(4, 3, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
out = image.crop(1, 1, 2, 2)
raise 'crop mismatch' unless gray_pixel(out, 0, 0) == 6 && gray_pixel(out, 1, 1) == 11
puts "crop #{gray_pixel(out, 0, 0)} #{gray_pixel(out, 1, 1)}"
RUBY
