#!/usr/bin/env bash
# @testcase: usage-ruby-vips-find-trim-custom-threshold
# @title: ruby-vips find_trim with custom threshold
# @description: Embeds a slightly off-background content rectangle inside a near-uniform canvas and uses Vips::Image#find_trim with an explicit threshold parameter to verify that the bounding box only includes pixels that exceed the threshold delta.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

bg_value = 200
content = (Vips::Image.black(7, 5) + 50).cast(:uchar)
canvas = content.embed(4, 2, 20, 14, extend: :background, background: [bg_value])
raise "canvas dims" unless canvas.width == 20 && canvas.height == 14

# A high threshold (60) requires |pixel - background| > 60. The content is
# at 50 and the background is at 200, |50 - 200| = 150 which clears 60, so
# the trim still locates the content rectangle.
left, top, width, height = canvas.find_trim(threshold: 60.0, background: [bg_value])
raise "trim left #{left}" unless left == 4
raise "trim top #{top}" unless top == 2
raise "trim width #{width}" unless width == 7
raise "trim height #{height}" unless height == 5

# A threshold larger than the contrast collapses the bbox to zero.
_l2, _t2, w2, h2 = canvas.find_trim(threshold: 200.0, background: [bg_value])
raise "expected empty bbox (#{w2}x#{h2})" unless w2 == 0 && h2 == 0

trimmed = canvas.crop(left, top, width, height)
out_path = File.join(tmpdir, "trim.png")
trimmed.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)
raise "trim mid pixel" unless trimmed.getpoint(3, 2) == [50.0]

puts "find_trim threshold=60 bbox=#{[left, top, width, height].inspect}"
RUBY

file "$tmpdir/trim.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/trim.png")" >&2; exit 1; }
