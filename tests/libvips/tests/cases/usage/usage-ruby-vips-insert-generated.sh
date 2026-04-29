#!/usr/bin/env bash
# @testcase: usage-ruby-vips-insert-generated
# @title: ruby-vips insert generated image
# @description: Inserts a smaller synthetic image into a base canvas with ruby-vips and verifies the output dimensions.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-insert-generated"
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

base = gray_image(6, 6, Array.new(36, 10))
patch = gray_image(2, 2, Array.new(4, 200))
out = base.insert(patch, 2, 2)
raise "insert mismatch" unless gray_pixel(out, 1, 1) == 10 && gray_pixel(out, 2, 2) == 200 && gray_pixel(out, 3, 3) == 200
puts "insert #{gray_pixel(out, 1, 1)} #{gray_pixel(out, 2, 2)}"
RUBY
