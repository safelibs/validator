#!/usr/bin/env bash
# @testcase: usage-ruby-vips-tilecache-roundtrip
# @title: ruby-vips tilecache preserves pixels through a cached pipeline
# @description: Pushes a synthetic image through a Vips::Image#tilecache stage with explicit tile width/height and threading and verifies that downstream operations see the same pixel values they would without the cache, exercising the lazy/persistent cache marker.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# 8x4 single-band image with a unique value per pixel so any cache-time
# mis-ordering would be detectable.
pixels = (0...32).map { |i| (i * 7 + 3) % 251 }
src = Vips::Image.new_from_memory(pixels.pack('C*'), 8, 4, 1, :uchar)
raise "src dims" unless src.width == 8 && src.height == 4

# Run the same downstream op (multiply by 2 in float, then cast) twice: once
# directly, once after a tilecache stage with non-default tile geometry.
direct = (src * 2).cast(:ushort)

cached = src.tilecache(tile_width: 4, tile_height: 2, max_tiles: 16, threaded: true, persistent: true)
raise "cache dims" unless cached.width == 8 && cached.height == 4
raise "cache bands" unless cached.bands == 1

via_cache = (cached * 2).cast(:ushort)
raise "via_cache dims" unless via_cache.width == 8 && via_cache.height == 4

# Pixel-for-pixel equality through the cache.
4.times do |y|
  8.times do |x|
    a = direct.getpoint(x, y)[0]
    b = via_cache.getpoint(x, y)[0]
    raise "diff (#{x},#{y}) direct=#{a} cached=#{b}" unless a == b
  end
end

# A small reduction must agree exactly as well.
raise "avg drift" unless (direct.avg - via_cache.avg).abs < 1e-9

out_path = File.join(tmpdir, "tilecache.tif")
via_cache.cast(:uchar).write_to_file(out_path)
raise "missing tif" unless File.size?(out_path)

puts "tilecache 4x2 ok avg=#{via_cache.avg.round(3)}"
RUBY

file "$tmpdir/tilecache.tif" | grep -qE 'TIFF image data' || { echo "not a TIFF: $(file "$tmpdir/tilecache.tif")" >&2; exit 1; }
