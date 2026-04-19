PYTHON ?= python3
CONFIG ?= repositories.yml
TESTS_ROOT ?= tests
ARTIFACT_ROOT ?= artifacts
SITE_ROOT ?= site
PROOF_OUTPUT ?= proof/validator-proof.json

.PHONY: unit check-testcases matrix proof site verify-site clean

unit:
	$(PYTHON) -m unittest discover -s unit -v

check-testcases:
	$(PYTHON) tools/testcases.py --config $(CONFIG) --tests-root $(TESTS_ROOT) --check-manifest-only

matrix:
	bash test.sh --config $(CONFIG) --tests-root $(TESTS_ROOT) --artifact-root $(ARTIFACT_ROOT) $(if $(LIBRARY),--library $(LIBRARY),) $(if $(RECORD_CASTS),--record-casts,)

proof:
	$(PYTHON) tools/verify_proof_artifacts.py --config $(CONFIG) --tests-root $(TESTS_ROOT) --artifact-root $(ARTIFACT_ROOT) --proof-output $(PROOF_OUTPUT) $(if $(LIBRARY),--library $(LIBRARY),) $(if $(RECORD_CASTS),--record-casts,)

site:
	$(PYTHON) tools/render_site.py --config $(CONFIG) --tests-root $(TESTS_ROOT) --results-root $(ARTIFACT_ROOT)/results --artifacts-root $(ARTIFACT_ROOT) --proof-path $(ARTIFACT_ROOT)/$(PROOF_OUTPUT) --output-root $(SITE_ROOT)

verify-site:
	bash scripts/verify-site.sh --config $(CONFIG) --results-root $(ARTIFACT_ROOT)/results --artifacts-root $(ARTIFACT_ROOT) --proof-path $(ARTIFACT_ROOT)/$(PROOF_OUTPUT) --tests-root $(TESTS_ROOT) --site-root $(SITE_ROOT)

clean:
	rm -rf .work $(ARTIFACT_ROOT) $(SITE_ROOT)
	find . -name __pycache__ -type d -prune -exec rm -rf {} +
