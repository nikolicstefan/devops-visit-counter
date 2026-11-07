VERSIONS_SCRIPT := scripts/versions.sh

RUFF := uv run ruff
MYPY := uv run mypy

.PHONY: \
	shellcheck \
	versions \
	tidy \
	tidy-imp \
	run \
	test

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

tidy:
	-$(RUFF) format .
	-$(RUFF) check --fix -v .
	-$(MYPY) .

tidy-imp:
	$(RUFF) check --select I --fix -v .

run:
	uv run uvicorn app.main:app --reload --host 127.0.0.1 --port "$${APP_PORT:-8000}"

test:
	curl http://127.0.0.1:8000/
