PYTHON ?= python3
CONFIG ?= repositories.yml
TESTS_ROOT ?= tests
ARTIFACT_ROOT ?= artifacts
SITE_ROOT ?= site
PROOF_OUTPUT ?= proof/original-validation-proof.json
PROOF_PATH ?= $(ARTIFACT_ROOT)/$(PROOF_OUTPUT)
SMOKE_LIBRARIES ?= cjson libarchive libuv libwebp
LIBRARIES ?= $(LIBRARY)
MIN_SOURCE_CASES ?= 0
MIN_USAGE_CASES ?= 0
MIN_CASES ?= 0
LIBRARY_ARGS = $(foreach library,$(LIBRARIES),--library $(library))

.PHONY: unit check-testcases matrix matrix-smoke proof site verify-site clean

unit:
	$(PYTHON) -m unittest discover -s unit -v

check-testcases:
	$(PYTHON) tools/testcases.py --config $(CONFIG) --tests-root $(TESTS_ROOT) --check-manifest-only

matrix:
	bash test.sh --config $(CONFIG) --tests-root $(TESTS_ROOT) --artifact-root $(ARTIFACT_ROOT) $(LIBRARY_ARGS) $(if $(RECORD_CASTS),--record-casts,)

matrix-smoke:
	bash test.sh --config $(CONFIG) --tests-root $(TESTS_ROOT) --artifact-root $(ARTIFACT_ROOT) --record-casts $(foreach library,$(SMOKE_LIBRARIES),--library $(library))

proof:
	$(PYTHON) tools/verify_proof_artifacts.py --config $(CONFIG) --tests-root $(TESTS_ROOT) --artifact-root $(ARTIFACT_ROOT) --proof-output $(PROOF_PATH) $(LIBRARY_ARGS) $(if $(or $(REQUIRE_CASTS),$(RECORD_CASTS)),--require-casts,) --min-source-cases $(MIN_SOURCE_CASES) --min-usage-cases $(MIN_USAGE_CASES) --min-cases $(MIN_CASES)

site:
	$(PYTHON) tools/render_site.py --config $(CONFIG) --tests-root $(TESTS_ROOT) --artifact-root $(ARTIFACT_ROOT) --proof-path $(PROOF_PATH) --output-root $(SITE_ROOT)

verify-site:
	bash scripts/verify-site.sh --config $(CONFIG) --tests-root $(TESTS_ROOT) --artifacts-root $(ARTIFACT_ROOT) --proof-path $(PROOF_PATH) --site-root $(SITE_ROOT) $(LIBRARY_ARGS)

clean:
	rm -rf .work $(ARTIFACT_ROOT) $(SITE_ROOT)
	find . -name __pycache__ -type d -prune -exec rm -rf {} +
