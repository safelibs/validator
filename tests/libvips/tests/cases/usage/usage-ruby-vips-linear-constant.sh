#!/usr/bin/env bash
# @testcase: usage-ruby-vips-linear-constant
# @title: ruby-vips linear constant
# @description: Applies a linear transform to a constant image with ruby-vips and verifies the output average.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-linear-constant"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" "$VALIDATOR_SAMPLE_ROOT" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]
sample_root = ARGV[2]

image = Vips::Image.black(4, 4, bands: 1) + 5
out = image.linear(3, 2)
raise "unexpected average" unless (out.avg - 17.0).abs < 0.01
puts "linear #{out.avg}"
RUBY
