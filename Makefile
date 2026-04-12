PYTHON ?= python3
CONFIG ?= repositories.yml
APT_CONFIG ?= /home/yans/safelibs/apt-repo/repositories.yml
WORKSPACE ?= .work
DEST_ROOT ?= $(WORKSPACE)/ports
RAW_INVENTORY ?= inventory/github-repo-list.json
FILTERED_INVENTORY ?= inventory/github-port-repos.json
DEST ?= .

.PHONY: unit inventory stage-ports build-safe import-assets clean

unit:
	$(PYTHON) -m unittest unit.test_inventory unit.test_stage_port_repos unit.test_build_safe_debs unit.test_import_port_assets unit.test_verify_imported_assets -v

inventory:
	mkdir -p inventory
	if [ -n "$${GH_TOKEN:-}" ]; then export GH_TOKEN; elif [ -n "$${SAFELIBS_REPO_TOKEN:-}" ]; then export GH_TOKEN="$$SAFELIBS_REPO_TOKEN"; else unset GH_TOKEN || true; fi; gh repo list safelibs --limit 200 --json name,nameWithOwner,isPrivate,url,defaultBranchRef > $(RAW_INVENTORY)
	$(PYTHON) tools/inventory.py --github-json $(RAW_INVENTORY) --apt-config $(APT_CONFIG) --write-filtered $(FILTERED_INVENTORY) --write-config $(CONFIG) --verify-scope

stage-ports:
	$(PYTHON) tools/stage_port_repos.py --config $(CONFIG) --workspace $(WORKSPACE) --dest-root $(DEST_ROOT) $(if $(SOURCE_ROOT),--source-root $(SOURCE_ROOT),) $(if $(LIBRARIES),--libraries $(LIBRARIES),)

build-safe:
	@test -n "$(LIBRARY)" || (echo "LIBRARY is required" >&2; exit 1)
	$(PYTHON) tools/build_safe_debs.py --config $(CONFIG) --library $(LIBRARY) --port-root $(DEST_ROOT) --workspace $(WORKSPACE) --output $(WORKSPACE)/debs/$(LIBRARY)

import-assets:
	@test -n "$(LIBRARY)" || (echo "LIBRARY is required" >&2; exit 1)
	$(PYTHON) tools/import_port_assets.py --config $(CONFIG) --library $(LIBRARY) --port-root $(DEST_ROOT) --workspace $(WORKSPACE) --dest-root $(DEST)

clean:
	rm -rf $(WORKSPACE)
	find . -name __pycache__ -type d -prune -exec rm -rf {} +
