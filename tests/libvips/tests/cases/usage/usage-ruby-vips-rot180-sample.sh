#!/usr/bin/env bash
# @testcase: usage-ruby-vips-rot180-sample
# @title: ruby-vips 180 degree rotation
# @description: Rotates the bundled JPEG sample by 180 degrees with ruby-vips and verifies the image dimensions remain stable.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-rot180-sample"
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

image = gray_image(2, 2, [10, 20, 30, 40])
out = image.rot180
expected = [40, 30, 20, 10]
actual = [
  gray_pixel(out, 0, 0),
  gray_pixel(out, 1, 0),
  gray_pixel(out, 0, 1),
  gray_pixel(out, 1, 1),
]
raise "rot180 mismatch #{actual.inspect}" unless actual == expected
puts "rot180 #{actual.join(',')}"
RUBY
