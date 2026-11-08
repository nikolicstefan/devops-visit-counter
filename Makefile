VERSIONS_SCRIPT := scripts/versions.sh
CI_WORKFLOW := .github/workflows/ci.yml

ACTIONLINT_IMAGE := rhysd/actionlint:1.7.12
ACT_RUNNER_IMAGE := catthehacker/ubuntu:act-24.04

RUFF_FMT := uv run ruff format
RUFF_CHK := uv run ruff check

.PHONY: \
	history \
	shellcheck \
	versions \
	py-format \
	py-format-check \
	py-lint \
	py-lint-fix \
	py-imports-fix \
	py-typecheck \
	py-test \
	ci-lint \
	ci-run \
	checks \
	formats \
	run \
	test

history:
	git log --oneline --graph --all --decorate

shellcheck:
	@test -n $(SCRIPT) || { \
		echo "Usage: make shellcheck SCRIPT=path/to/script.sh" >&2; \
		exit 1; \
	}
	@test -f $(SCRIPT) || { \
		echo "Script not found: $(SCRIPT)" >&2; \
		exit 1; \
	}
	bash -n $(SCRIPT)
	shellcheck $(SCRIPT)

versions:
	@test -f $(VERSIONS_SCRIPT) || { \
		echo "Script not found: $(VERSIONS_SCRIPT)" >&2; \
		exit 1; \
	}
	@if [ ! -x "$(VERSIONS_SCRIPT)" ]; then \
		echo "chmod +x $(VERSIONS_SCRIPT)"; \
		chmod +x $(VERSIONS_SCRIPT); \
	fi
	$(VERSIONS_SCRIPT)

py-format:
	$(RUFF_FMT) .

py-format-check:
	$(RUFF_FMT) --check .

py-lint:
	$(RUFF_CHK) .

py-lint-fix:
	$(RUFF_CHK) --fix -v .

py-imports-fix:
	$(RUFF_CHK) --select I --fix -v .

py-typecheck:
	uv run mypy .

py-test:
	uv run python -m pytest

ci-lint:
	docker run --rm \
		-v "$(CURDIR):/repo" \
		-w /repo \
		$(ACTIONLINT_IMAGE) \
		-color

ci-run:
	act push \
		-W $(CI_WORKFLOW) \
		-j checks \
		-P ubuntu-24.04=$(ACT_RUNNER_IMAGE)

checks:
	-$(MAKE) shellcheck SCRIPT=$(VERSIONS_SCRIPT)
	-$(MAKE) py-format-check
	-$(MAKE) py-lint
	-$(MAKE) py-typecheck
	-$(MAKE) py-test
	-$(MAKE) ci-lint

formats:
	-$(MAKE) py-format
	-$(MAKE) py-lint-fix

run:
	uv run uvicorn app.main:app --reload --host 127.0.0.1 --port "$${APP_PORT:-8000}"

test:
	curl http://127.0.0.1:8000/
