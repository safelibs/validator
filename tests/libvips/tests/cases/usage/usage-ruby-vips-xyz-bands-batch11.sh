#!/usr/bin/env bash
# @testcase: usage-ruby-vips-xyz-bands-batch11
# @title: ruby-vips xyz bands
# @description: Creates an xyz image with ruby-vips and checks its band count.
# @timeout: 180
# @tags: usage, vips, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-xyz-bands-batch11"
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

image = Vips::Image.xyz(3, 2)
raise "xyz bands" unless image.bands == 2 && image.width == 3 && image.height == 2
puts "xyz #{image.bands}"
RUBY
