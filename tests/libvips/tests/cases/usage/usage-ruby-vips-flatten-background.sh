#!/usr/bin/env bash
# @testcase: usage-ruby-vips-flatten-background
# @title: ruby-vips flatten background
# @description: Flattens a generated RGBA image onto a solid background with ruby-vips and verifies the alpha channel is removed.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-flatten-background"
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

image = multiband_image(1, 1, 4, [10, 20, 30, 128])
out = image.flatten(background: [255, 255, 255])
assert_close_rgb(out, 0, 0, [132, 137, 142])
puts "flatten #{pixel_values(out, 0, 0).join(',')}"
RUBY
