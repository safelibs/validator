#!/usr/bin/env bash
# @testcase: usage-ruby-vips-invert-image
# @title: ruby-vips invert image
# @description: Inverts an image with ruby-vips and verifies the average pixel value changes.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-invert-image"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" "$VALIDATOR_SAMPLE_ROOT" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]
sample_root = ARGV[2]

image = Vips::Image.black(4, 4, bands: 1).cast("uchar") + 10
inverted = image.invert
raise "unexpected average" unless inverted.avg != image.avg
puts "invert #{inverted.avg}"
RUBY
