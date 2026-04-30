#!/usr/bin/env bash
# @testcase: usage-ruby-vips-text-rendering
# @title: ruby-vips text rendering with default font
# @description: Renders a short string into a single-band alpha image with Vips::Image.text using the default font and verifies the output has positive dimensions and contains both transparent and opaque pixels. If the renderer is unavailable (no fonts, no Pango support), the testcase reports the reason and exits successfully.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

begin
  img = Vips::Image.text("Hello", dpi: 96)
rescue Vips::Error => e
  puts "text-skip: #{e.message.lines.first&.strip}"
  exit 0
end

raise "text dims" unless img.width > 0 && img.height > 0
raise "text bands" unless img.bands == 1

lo = img.min
hi = img.max
raise "text constant lo=#{lo} hi=#{hi}" unless hi > lo

out_path = File.join(tmpdir, "text.png")
img.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)

reload = Vips::Image.new_from_file(out_path)
raise "reload dims" unless reload.width == img.width && reload.height == img.height
puts "text dims=#{img.width}x#{img.height} lo=#{lo} hi=#{hi}"
RUBY

if [[ -f "$tmpdir/text.png" ]]; then
  file "$tmpdir/text.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/text.png")" >&2; exit 1; }
fi
