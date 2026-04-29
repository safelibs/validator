#!/usr/bin/env bash
# @testcase: usage-ruby-vips-extract-area-generated
# @title: ruby-vips extract area generated
# @description: Crops a generated image with ruby-vips extract_area and verifies the selected output dimensions.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-extract-area-generated"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]

def gray_image(width, height, pixels)
  Vips::Image.new_from_memory(pixels.pack("C*"), width, height, 1, :uchar)
end

def multiband_image(width, height, bands, pixels)
  Vips::Image.new_from_memory(pixels.pack("C*"), width, height, bands, :uchar)
end

def pixel_values(image, x, y)
  image.extract_area(x, y, 1, 1).write_to_memory.bytes
end

def gray_pixel(image, x, y)
  pixel_values(image, x, y)[0]
end

def assert_close_rgb(image, x, y, expected)
  actual = pixel_values(image, x, y)
  unless actual.zip(expected).all? { |value, want| (value - want).abs <= 1 }
    raise "unexpected rgb #{actual.inspect} != #{expected.inspect}"
  end
end

image = gray_image(4, 3, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
out = image.extract_area(1, 1, 2, 2)
actual = [
  gray_pixel(out, 0, 0),
  gray_pixel(out, 1, 0),
  gray_pixel(out, 0, 1),
  gray_pixel(out, 1, 1),
]
raise "extract mismatch #{actual.inspect}" unless actual == [6, 7, 10, 11]
puts "extract #{actual.join(',')}"
RUBY
