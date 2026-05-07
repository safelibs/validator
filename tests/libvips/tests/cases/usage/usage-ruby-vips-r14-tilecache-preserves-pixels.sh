#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r14-tilecache-preserves-pixels
# @title: ruby-vips Image#tilecache preserves pixels through the cache stage
# @description: Pushes a 6x6 single-band uchar image with a known per-pixel pattern through Vips::Image#tilecache(tile_width: 2, tile_height: 2, max_tiles: 9), then verifies dimensions are unchanged, bands are unchanged, and getpoint at three sampled coordinates returns the same values as the uncached source, asserting libvips' tilecache is value-preserving.
# @timeout: 60
# @tags: usage, vips, ruby, tilecache
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
pixels = (0...36).map { |i| ((i * 5) + 7) % 200 }
src = Vips::Image.new_from_memory(pixels.pack('C*'), 6, 6, 1, :uchar)

cached = src.tilecache(tile_width: 2, tile_height: 2, max_tiles: 9)
raise "cached dims=#{cached.width}x#{cached.height}" unless cached.width == 6 && cached.height == 6
raise "cached bands=#{cached.bands}" unless cached.bands == 1

[[0, 0], [3, 2], [5, 5]].each do |x, y|
  raw = src.getpoint(x, y)
  thr = cached.getpoint(x, y)
  raise "tilecache (#{x},#{y}) raw=#{raw.inspect} cached=#{thr.inspect}" unless raw == thr
end
puts "tilecache 2x2 ok dims=#{cached.width}x#{cached.height}"
RUBY
