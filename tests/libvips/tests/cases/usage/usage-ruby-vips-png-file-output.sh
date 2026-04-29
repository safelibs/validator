#!/usr/bin/env bash
# @testcase: usage-ruby-vips-png-file-output
# @title: ruby-vips PNG file output
# @description: Saves a synthetic PNG with ruby-vips, reloads it, and verifies the output file is nonempty and decodable.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-png-file-output"
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

image = gray_image(2, 2, [90, 100, 110, 120])
path = File.join(tmpdir, "out.png")
image.write_to_file(path)
reload = Vips::Image.new_from_file(path)
actual = [
  gray_pixel(reload, 0, 0),
  gray_pixel(reload, 1, 0),
  gray_pixel(reload, 0, 1),
  gray_pixel(reload, 1, 1),
]
raise "png reload mismatch #{actual.inspect}" unless actual == [90, 100, 110, 120]
puts "png #{actual.join(',')}"
RUBY
