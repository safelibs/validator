#!/usr/bin/env bash
set -euo pipefail

/validator/tests/_shared/install_safe_debs.sh
exec /validator/tests/_shared/run_library_tests.sh libexif
