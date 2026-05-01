#!/usr/bin/env bash
# @testcase: usage-ruby-vips-draw-rect-mutable
# @title: ruby-vips draw_rect filled rectangle
# @description: Paints a filled rectangle on a mutable canvas via Vips::MutableImage#draw_rect! and verifies that pixels strictly inside the rectangle carry the ink while pixels just outside the rectangle remain at the background value.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

base = (Vips::Image.black(30, 30) + 10).cast(:uchar)
painted = base.mutate do |m|
  m.draw_rect!([240], 5, 7, 10, 6, fill: true)
end

raise "dims" unless painted.width == 30 && painted.height == 30

# Inside the rectangle [5,7] - [14,12].
[[5, 7], [10, 9], [14, 12], [9, 8]].each do |x, y|
  v = painted.getpoint(x, y)
  raise "inside (#{x},#{y})=#{v.inspect}" unless v == [240.0]
end

# Just outside the rectangle.
[[4, 7], [5, 6], [15, 9], [10, 13], [0, 0], [29, 29]].each do |x, y|
  v = painted.getpoint(x, y)
  raise "outside (#{x},#{y})=#{v.inspect}" unless v == [10.0]
end

out_path = File.join(tmpdir, "rect.png")
painted.write_to_file(out_path)
raise "missing png" unless File.size?(out_path)
puts "draw_rect ok"
RUBY

file "$tmpdir/rect.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/rect.png")" >&2; exit 1; }
