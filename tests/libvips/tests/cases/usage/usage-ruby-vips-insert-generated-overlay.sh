#!/usr/bin/env bash
# @testcase: usage-ruby-vips-insert-generated-overlay
# @title: ruby-vips generated overlay insert
# @description: Exercises ruby-vips generated overlay insert through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-insert-generated-overlay"
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

base = gray_image(4, 4, Array.new(16, 10))
patch = gray_image(2, 2, Array.new(4, 200))
out = base.insert(patch, 1, 1)
raise 'insert mismatch' unless gray_pixel(out, 1, 1) == 200 && gray_pixel(out, 0, 0) == 10
puts "insert #{gray_pixel(out, 1, 1)}"
RUBY
