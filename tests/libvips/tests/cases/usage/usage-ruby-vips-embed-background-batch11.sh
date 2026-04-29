#!/usr/bin/env bash
# @testcase: usage-ruby-vips-embed-background-batch11
# @title: ruby-vips embed background
# @description: Embeds an image on a background canvas with ruby-vips.
# @timeout: 180
# @tags: usage, vips, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-embed-background-batch11"
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

image = gray_image(1, 1, [70])
out = image.embed(1, 1, 3, 3, background: [9])
values = bytes(out)
raise "embed background" unless values[0] == 9 && values[4] == 70
puts "embed #{values.join(',')}"
RUBY
