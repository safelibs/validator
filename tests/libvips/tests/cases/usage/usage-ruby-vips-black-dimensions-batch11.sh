#!/usr/bin/env bash
# @testcase: usage-ruby-vips-black-dimensions-batch11
# @title: ruby-vips black dimensions
# @description: Creates a black image with ruby-vips and checks dimensions.
# @timeout: 180
# @tags: usage, vips, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-black-dimensions-batch11"
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

def bytes(image)
  image.cast(:uchar).write_to_memory.bytes
end

image = Vips::Image.black(3, 2)
raise "black dimensions" unless image.width == 3 && image.height == 2
puts "black #{image.width}x#{image.height}"
RUBY
