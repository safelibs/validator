#!/usr/bin/env bash
# @testcase: usage-ruby-vips-sharpen-roundtrip
# @title: ruby-vips sharpen roundtrip
# @description: Applies sharpen to a synthetic RGB image, writes the result as TIFF, and re-reads it to verify dimensions and band count.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Declare an sRGB interpretation so vips can route through labs for sharpen,
# then convert the labs result back to sRGB before saving as TIFF.
base = (Vips::Image.black(32, 32, bands: 3) + [128, 64, 200]).cast(:uchar).copy(interpretation: :srgb)
sharpened = base.sharpen(sigma: 1.0).colourspace(:srgb)
raise "size" unless sharpened.width == 32 && sharpened.height == 32
raise "bands" unless sharpened.bands == 3

out_path = File.join(tmpdir, "sharp.tif")
sharpened.cast(:uchar).write_to_file(out_path)
raise "missing tif" unless File.size?(out_path)

reload = Vips::Image.new_from_file(out_path)
raise "reload size" unless reload.width == 32 && reload.height == 32
raise "reload bands" unless reload.bands == 3
puts "sharpen #{reload.width}x#{reload.height}"
RUBY

file "$tmpdir/sharp.tif" | grep -qE 'TIFF image data' || { echo "not a TIFF: $(file "$tmpdir/sharp.tif")" >&2; exit 1; }
