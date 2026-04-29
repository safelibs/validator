#!/usr/bin/env bash
# @testcase: usage-ruby-vips-gaussblur-sample
# @title: ruby-vips gaussblur sample
# @description: Applies Gaussian blur to a PNG fixture with ruby-vips and verifies the dimensions stay constant.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-gaussblur-sample"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" "$VALIDATOR_SAMPLE_ROOT" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]
sample_root = ARGV[2]

path = File.join(sample_root, "test/test-suite/images/sample.png")
image = Vips::Image.new_from_file(path)
out = image.gaussblur(0.8)
raise "unexpected blur size" unless out.width == image.width && out.height == image.height
puts "gaussblur #{out.width}x#{out.height}"
RUBY
