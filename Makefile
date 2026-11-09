include .env
export

RUFF_FMT := uv run ruff format
RUFF_CHK := uv run ruff check
COMPOSE := docker compose

VERSIONS_SCRIPT := scripts/versions.sh
CI_WORKFLOW := .github/workflows/ci.yml

ACTIONLINT_IMAGE := rhysd/actionlint:1.7.12
ACT_RUNNER_IMAGE := catthehacker/ubuntu:act-24.04
HADOLINT_IMAGE := hadolint/hadolint:v2.15.1

APP_IMAGE := visit-counter
APP_HOST_PORT := $(APP_PORT)
APP_CONTAINER_PORT := $(APP_PORT)

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
	docker-lint \
	compose-lint \
	ci-lint \
	ci-run \
	checks \
	formats \
	run \
	test-index \
	docker-build \
	docker-run \
	compose-build \
	compose-up \
	compose-up-wait \
	compose-down \
	compose-reset \
	compose-logs \
	compose-logs-app \
	compose-ps \
	compose-test-index

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

docker-lint:
	docker run --rm -i $(HADOLINT_IMAGE) < Dockerfile

compose-lint:
	$(COMPOSE) config --quiet

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
	$(MAKE) shellcheck SCRIPT=$(VERSIONS_SCRIPT)
	$(MAKE) py-format-check
	$(MAKE) py-lint
	$(MAKE) py-typecheck
	$(MAKE) py-test
	$(MAKE) docker-lint
	$(MAKE) compose-lint
	$(MAKE) ci-lint
	$(MAKE) compose-test-index

formats:
	$(MAKE) py-format
	$(MAKE) py-lint-fix
	$(MAKE) py-typecheck

run:
	uv run uvicorn app.main:app --reload --host 127.0.0.1 --port "$${APP_PORT:-$(APP_HOST_PORT)}"

test-index:
	response="$$(curl --fail-with-body --silent --show-error http://127.0.0.1:$(APP_HOST_PORT)/)"; \
	printf '%s\n' "$$response" | grep -q '"message"[[:space:]]*:[[:space:]]*"Hello DevOps"'; \
	printf '%s\n' "$$response" | grep -qE '"host"[[:space:]]*:[[:space:]]*"[^"]+"'

docker-build:
	docker build -t $(APP_IMAGE) .

docker-run:
	docker run --rm \
		--name $(APP_IMAGE) \
		-p $(APP_HOST_PORT):$(APP_CONTAINER_PORT) \
		$(APP_IMAGE)

compose-build:
	$(COMPOSE) build

compose-up:
	$(COMPOSE) up -d --build

compose-up-wait:
	$(COMPOSE) up -d --build --wait --wait-timeout 60

compose-down:
	$(COMPOSE) down --remove-orphans

compose-restart:
	$(COMPOSE) down --remove-orphans -v
	$(MAKE) compose-up

compose-logs:
	$(COMPOSE) logs -f

compose-logs-app:
	$(COMPOSE) logs -f app

compose-ps:
	$(COMPOSE) ps --all

compose-test-index:
	@set -eu; \
	trap '$(MAKE) compose-down' EXIT; \
	$(MAKE) compose-up-wait; \
	$(MAKE) test-index
