#!/usr/bin/env bash
# @testcase: usage-ruby-vips-crop-sample-jpeg
# @title: ruby-vips crop sample JPEG
# @description: Loads a JPEG fixture with ruby-vips, crops the top-left region, and checks the output size.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-crop-sample-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" "$VALIDATOR_SAMPLE_ROOT" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]
sample_root = ARGV[2]

path = File.join(sample_root, "test/test-suite/images/sample.jpg")
image = Vips::Image.new_from_file(path)
width = [image.width, 10].min
height = [image.height, 10].min
out = image.crop(0, 0, width, height)
raise "unexpected crop" unless out.width == width && out.height == height
puts "crop #{out.width}x#{out.height}"
RUBY
