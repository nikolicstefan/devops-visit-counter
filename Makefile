include .env
export

RUFF_FMT := uv run ruff format
RUFF_CHK := uv run ruff check
COMPOSE := docker compose

VERSIONS_SCRIPT := scripts/versions.sh
HEALTHCHECK_SCRIPT := scripts/healthcheck.sh
CI_WORKFLOW := .github/workflows/ci.yml

ACTIONLINT_IMAGE := rhysd/actionlint:1.7.12
ACT_RUNNER_IMAGE := catthehacker/ubuntu:act-24.04
HADOLINT_IMAGE := hadolint/hadolint:v2.15.1

APP_IMAGE := visit-counter

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
	test-visits \
	test-visits-persistence \
	healthcheck \
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
	compose-tests

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

run:
	uv run uvicorn app.main:app --reload --host $(APP_URL) --port "$${APP_PORT:-$(APP_PUBLIC_PORT)}"

define TEST_INDEX_SCRIPT
import json
import sys

data = json.loads(sys.argv[1])

assert data["message"] == "Hello DevOps"
assert isinstance(data["host"], str) and data["host"]
endef
export TEST_INDEX_SCRIPT

test-index:
	@response="$$(curl --fail-with-body --silent --show-error $(APP_URL):$(APP_PUBLIC_PORT)/)"; \
	uv run python -c "$$TEST_INDEX_SCRIPT" "$$response"

define TEST_VISITS_SCRIPT
import json
import sys

first_visits = json.loads(sys.argv[1])["visits"]
second_visits = json.loads(sys.argv[2])["visits"]

assert second_visits == first_visits + 1, (first_visits, second_visits)

print(second_visits)
endef
export TEST_VISITS_SCRIPT

test-visits:
	@first_response="$$(curl --fail-with-body --silent --show-error $(APP_URL):$(APP_PUBLIC_PORT)/visits)"; \
	second_response="$$(curl --fail-with-body --silent --show-error $(APP_URL):$(APP_PUBLIC_PORT)/visits)"; \
	uv run python -c "$$TEST_VISITS_SCRIPT" "$$first_response" "$$second_response"

define TEST_PERSISTENCE_SCRIPT
import json
import sys

saved_visits = int(sys.argv[1])
current_visits = json.loads(sys.argv[2])["visits"]

assert current_visits == saved_visits + 1, (saved_visits, current_visits)
endef
export TEST_PERSISTENCE_SCRIPT

test-visits-persistence:
	@response="$$(curl --fail-with-body --silent --show-error $(APP_URL):$(APP_PUBLIC_PORT)/visits)"; \
	uv run python -c "$$TEST_PERSISTENCE_SCRIPT" "$(SAVED_VISITS)" "$$response"

healthcheck:
	@test -f $(HEALTHCHECK_SCRIPT) || { \
		echo "Script not found: $(HEALTHCHECK_SCRIPT)" >&2; \
		exit 1; \
	}
	@if [ ! -x "$(HEALTHCHECK_SCRIPT)" ]; then \
		echo "chmod +x $(HEALTHCHECK_SCRIPT)"; \
		chmod +x $(HEALTHCHECK_SCRIPT); \
	fi
	@test -n "$(URL)" || { \
		echo "Usage: make healthcheck URL=http://localhost:8080" >&2; \
		exit 1; \
	}
	$(HEALTHCHECK_SCRIPT) "$(URL)"

docker-build:
	docker build -t $(APP_IMAGE) .

docker-run:
	docker run --rm \
		--name $(APP_IMAGE) \
		-p $(APP_PUBLIC_PORT):$(APP_PORT) \
		$(APP_IMAGE)

compose-build:
	$(COMPOSE) build

compose-up:
	$(COMPOSE) up -d --build

compose-up-wait:
	$(COMPOSE) up -d --build --wait

compose-down:
	$(COMPOSE) down --remove-orphans

compose-reset:
	$(COMPOSE) down --remove-orphans -v
	$(MAKE) compose-up

compose-logs:
	$(COMPOSE) logs -f

compose-logs-app:
	$(COMPOSE) logs -f app

compose-ps:
	$(COMPOSE) ps --all

compose-tests:
	@set -eu; \
	trap '$(MAKE) compose-down' EXIT; \
	$(MAKE) compose-up-wait; \
	$(MAKE) healthcheck URL=$(APP_URL):$(APP_PUBLIC_PORT); \
	$(MAKE) test-index; \
	VISITS="$$($(MAKE) --silent --no-print-directory test-visits)"; \
	test -n "$$VISITS"; \
	$(MAKE) compose-down; \
	$(MAKE) compose-up-wait; \
	$(MAKE) healthcheck URL=$(APP_URL):$(APP_PUBLIC_PORT); \
	$(MAKE) test-visits-persistence SAVED_VISITS="$$VISITS"

checks:
	$(MAKE) shellcheck SCRIPT=$(VERSIONS_SCRIPT)
	$(MAKE) shellcheck SCRIPT=$(HEALTHCHECK_SCRIPT)
	$(MAKE) py-format-check
	$(MAKE) py-lint
	$(MAKE) py-typecheck
	$(MAKE) py-test
	$(MAKE) docker-lint
	$(MAKE) compose-lint
	$(MAKE) ci-lint
	$(MAKE) compose-tests

formats:
	$(MAKE) py-format
	$(MAKE) py-lint-fix
	$(MAKE) py-typecheck
