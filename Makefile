PYTHON ?= python3
CONFIG ?= repositories.yml
TESTS_ROOT ?= tests
ARTIFACT_ROOT ?= artifacts
SITE_ROOT ?= site
PROOF_OUTPUT ?= proof/original-validation-proof.json
PROOF_PATH ?= $(ARTIFACT_ROOT)/$(PROOF_OUTPUT)
PORT_REPOS ?= inventory/github-port-repos.json
PORT_MODE ?= port-04-test
PORT_DEB_ROOT ?= $(ARTIFACT_ROOT)/debs/$(PORT_MODE)
PORT_LOCK_PATH ?= $(ARTIFACT_ROOT)/proof/$(PORT_MODE)-debs-lock.json
ORIGINAL_PROOF_PATH ?= $(ARTIFACT_ROOT)/proof/original-validation-proof.json
PORT_PROOF_PATH ?= $(ARTIFACT_ROOT)/proof/$(PORT_MODE)-validation-proof.json
SMOKE_LIBRARIES ?= cjson libarchive libuv libwebp
LIBRARIES ?= $(LIBRARY)
MIN_SOURCE_CASES ?= 0
MIN_USAGE_CASES ?= 0
MIN_CASES ?= 0
LIBRARY_ARGS = $(foreach library,$(LIBRARIES),--library $(library))

.PHONY: unit check-testcases fetch-port-debs matrix matrix-original matrix-port matrix-dual matrix-smoke proof proof-original proof-port proof-dual site site-dual verify-site verify-site-dual clean

unit:
	$(PYTHON) -m unittest discover -s unit -v

check-testcases:
	$(PYTHON) tools/testcases.py --config $(CONFIG) --tests-root $(TESTS_ROOT) --check --min-source-cases 120 --min-usage-cases 243 --min-cases 363

fetch-port-debs:
	$(PYTHON) tools/fetch_port_debs.py --config $(CONFIG) --port-repos $(PORT_REPOS) --output-root $(PORT_DEB_ROOT) --lock-output $(PORT_LOCK_PATH) $(LIBRARY_ARGS)

matrix: matrix-original

matrix-original:
	bash test.sh --config $(CONFIG) --tests-root $(TESTS_ROOT) --artifact-root $(ARTIFACT_ROOT) --mode original $(LIBRARY_ARGS) $(if $(RECORD_CASTS),--record-casts,)

matrix-port:
	bash test.sh --config $(CONFIG) --tests-root $(TESTS_ROOT) --artifact-root $(ARTIFACT_ROOT) --mode $(PORT_MODE) --override-deb-root $(PORT_DEB_ROOT) --port-deb-lock $(PORT_LOCK_PATH) $(LIBRARY_ARGS) $(if $(RECORD_CASTS),--record-casts,)

matrix-dual: matrix-original matrix-port

matrix-smoke:
	bash test.sh --config $(CONFIG) --tests-root $(TESTS_ROOT) --artifact-root $(ARTIFACT_ROOT) --mode original --record-casts $(foreach library,$(SMOKE_LIBRARIES),--library $(library))

proof: proof-original

proof-original:
	$(PYTHON) tools/verify_proof_artifacts.py --config $(CONFIG) --tests-root $(TESTS_ROOT) --artifact-root $(ARTIFACT_ROOT) --proof-output $(PROOF_PATH) --mode original $(LIBRARY_ARGS) $(if $(or $(REQUIRE_CASTS),$(RECORD_CASTS)),--require-casts,) --min-source-cases $(MIN_SOURCE_CASES) --min-usage-cases $(MIN_USAGE_CASES) --min-cases $(MIN_CASES)

proof-port:
	$(PYTHON) tools/verify_proof_artifacts.py --config $(CONFIG) --tests-root $(TESTS_ROOT) --artifact-root $(ARTIFACT_ROOT) --proof-output $(PORT_PROOF_PATH) --mode $(PORT_MODE) $(LIBRARY_ARGS) $(if $(or $(REQUIRE_CASTS),$(RECORD_CASTS)),--require-casts,) --min-source-cases $(MIN_SOURCE_CASES) --min-usage-cases $(MIN_USAGE_CASES) --min-cases $(MIN_CASES)

proof-dual: proof-original proof-port

site:
	$(PYTHON) tools/render_site.py --config $(CONFIG) --tests-root $(TESTS_ROOT) --artifact-root $(ARTIFACT_ROOT) --proof-path $(PROOF_PATH) --output-root $(SITE_ROOT)

site-dual:
	$(PYTHON) tools/render_site.py --config $(CONFIG) --tests-root $(TESTS_ROOT) --artifact-root $(ARTIFACT_ROOT) --proof-path $(ORIGINAL_PROOF_PATH) --proof-path $(PORT_PROOF_PATH) --output-root $(SITE_ROOT)

verify-site:
	bash scripts/verify-site.sh --config $(CONFIG) --tests-root $(TESTS_ROOT) --artifacts-root $(ARTIFACT_ROOT) --proof-path $(PROOF_PATH) --site-root $(SITE_ROOT) $(LIBRARY_ARGS)

verify-site-dual:
	bash scripts/verify-site.sh --config $(CONFIG) --tests-root $(TESTS_ROOT) --artifacts-root $(ARTIFACT_ROOT) --proof-path $(ORIGINAL_PROOF_PATH) --proof-path $(PORT_PROOF_PATH) --site-root $(SITE_ROOT) $(LIBRARY_ARGS)

clean:
	rm -rf .work $(ARTIFACT_ROOT) $(SITE_ROOT)
	find . -name __pycache__ -type d -prune -exec rm -rf {} +
