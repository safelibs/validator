#!/usr/bin/env bash
# @testcase: usage-ruby-vips-threshold-empty
# @title: ruby-vips empty threshold
# @description: Applies a threshold that no pixels exceed and verifies the resulting mask is empty.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-threshold-empty"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" "$VALIDATOR_SAMPLE_ROOT" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]
sample_root = ARGV[2]

image = Vips::Image.black(4, 4, bands: 1) + 10
mask = image > 200
raise "unexpected mask" unless mask.avg == 0
puts "threshold #{mask.avg}"
RUBY
