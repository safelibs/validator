#!/usr/bin/env bash
# @testcase: usage-ruby-vips-smartcrop-attention
# @title: ruby-vips smartcrop attention strategy
# @description: Crops a non-square synthetic RGB image into a square thumb using Vips::Image#smartcrop with the :attention strategy and verifies output dimensions and band count.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Build a 120x60 sRGB image with a bright spot the attention model should latch
# onto. Background grey, with a vivid square offset to the right.
base = (Vips::Image.black(120, 60, bands: 3) + [80, 80, 80]).cast(:uchar).copy(interpretation: :srgb)
spot = (Vips::Image.black(20, 20, bands: 3) + [240, 30, 30]).cast(:uchar).copy(interpretation: :srgb)
src = base.insert(spot, 80, 20)
raise "src dims" unless src.width == 120 && src.height == 60
raise "src bands" unless src.bands == 3

out = src.smartcrop(48, 48, interesting: :attention)
raise "smartcrop dims #{out.width}x#{out.height}" unless out.width == 48 && out.height == 48
raise "smartcrop bands" unless out.bands == 3

out_path = File.join(tmpdir, "smartcrop.png")
out.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)

reload = Vips::Image.new_from_file(out_path)
raise "reload dims" unless reload.width == 48 && reload.height == 48
puts "smartcrop attention #{out.width}x#{out.height}"
RUBY

file "$tmpdir/smartcrop.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/smartcrop.png")" >&2; exit 1; }
