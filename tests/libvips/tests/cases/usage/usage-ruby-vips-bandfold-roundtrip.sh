#!/usr/bin/env bash
# @testcase: usage-ruby-vips-bandfold-roundtrip
# @title: ruby-vips bandfold and bandunfold round-trip
# @description: Folds a wide single-band image into a multi-band image with Vips::Image#bandfold(factor: 3), verifies the resulting width and band count, then unfolds it back and checks that the round-trip restores the original layout pixel-for-pixel.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Wide 1-band image; width must be a multiple of the fold factor.
pixels = [
  1, 2, 3, 4, 5, 6, 7, 8, 9,
  11, 12, 13, 14, 15, 16, 17, 18, 19,
]
src = Vips::Image.new_from_memory(pixels.pack('C*'), 9, 2, 1, :uchar)
raise "src bands" unless src.bands == 1
raise "src dims" unless src.width == 9 && src.height == 2

folded = src.bandfold(factor: 3)
raise "folded bands #{folded.bands}" unless folded.bands == 3
raise "folded dims #{folded.width}x#{folded.height}" unless folded.width == 3 && folded.height == 2

# First column carries (1, 2, 3); third column carries (7, 8, 9).
first = folded.getpoint(0, 0).map { |v| v.round }
last = folded.getpoint(2, 0).map { |v| v.round }
raise "fold first #{first.inspect}" unless first == [1, 2, 3]
raise "fold last #{last.inspect}" unless last == [7, 8, 9]

unfolded = folded.bandunfold(factor: 3)
raise "unfold bands" unless unfolded.bands == 1
raise "unfold dims" unless unfolded.width == 9 && unfolded.height == 2

# Pixel-for-pixel comparison via memory dump.
raise "roundtrip bytes" unless unfolded.cast(:uchar).write_to_memory.bytes == pixels

out_path = File.join(tmpdir, "fold.tif")
folded.cast(:uchar).write_to_file(out_path)
raise "missing tif" unless File.size?(out_path)
puts "bandfold #{folded.width}x#{folded.height} bands=#{folded.bands}"
RUBY

file "$tmpdir/fold.tif" | grep -qE 'TIFF image data' || { echo "not a TIFF: $(file "$tmpdir/fold.tif")" >&2; exit 1; }
