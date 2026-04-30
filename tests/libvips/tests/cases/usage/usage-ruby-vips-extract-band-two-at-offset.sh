#!/usr/bin/env bash
# @testcase: usage-ruby-vips-extract-band-two-at-offset
# @title: ruby-vips extract_band n=2 starting at offset 1
# @description: Builds a 4-band image with distinct per-band values and uses Vips::Image#extract_band with n=2 starting at band 1 to slice out a 2-band image, verifying band count and the surviving channel values.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# A 4-band image with bands carrying values 11, 22, 33, 44.
src = (Vips::Image.black(6, 4, bands: 4) + [11, 22, 33, 44]).cast(:uchar)
raise "src bands" unless src.bands == 4

# extract_band(1, n: 2) -> bands [22, 33].
two = src.extract_band(1, n: 2)
raise "two bands #{two.bands}" unless two.bands == 2
raise "two dims" unless two.width == 6 && two.height == 4

px = two.getpoint(2, 2)
raise "two values #{px.inspect}" unless px.map { |v| v.round } == [22, 33]

# extract_band(2, n: 2) should give the trailing two bands [33, 44].
tail = src.extract_band(2, n: 2)
raise "tail bands" unless tail.bands == 2
tpx = tail.getpoint(0, 0)
raise "tail values #{tpx.inspect}" unless tpx.map { |v| v.round } == [33, 44]

out_path = File.join(tmpdir, "extract-two.tif")
two.cast(:uchar).write_to_file(out_path)
raise "missing tif" unless File.size?(out_path)
puts "extract_band offset=1 n=2 -> #{px.inspect}"
RUBY

file "$tmpdir/extract-two.tif" | grep -qE 'TIFF image data' || { echo "not a TIFF: $(file "$tmpdir/extract-two.tif")" >&2; exit 1; }
