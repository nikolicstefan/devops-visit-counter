-include .env

APP_HOST := $(or $(strip $(APP_HOST)),127.0.0.1)
APP_PORT := $(or $(strip $(APP_PORT)),8000)
APP_PUBLIC_PORT := $(or $(strip $(APP_PUBLIC_PORT)),8080)

REDIS_HOST := $(or $(strip $(REDIS_HOST)),redis)
REDIS_PORT := $(or $(strip $(REDIS_PORT)),6379)

RUFF_FMT := uv run ruff format
RUFF_CHK := uv run ruff check
COMPOSE := docker compose

APP_URL := http://$(APP_HOST)
APP_NAME := visit-counter
REDIS_NAME := redis

APP_NETWORK_NAME := app-net
REDIS_VOLUME_NAME := redis-data
REDIS_VOLUME := "$(REDIS_VOLUME_NAME):/data"
CHECKMAKE_WORKDIR := /
CHECKMAKE_VOLUME := "$(CURDIR)/Makefile:/Makefile:ro"
CHECKMAKE_INI_VOLUME := "$(CURDIR)/checkmake.ini:/checkmake.ini:ro"
ACTIONLINT_WORKDIR := /repo
ACTIONLINT_VOLUME := "$(CURDIR):$(ACTIONLINT_WORKDIR)"

CHECKMAKE_IMAGE := quay.io/checkmake/checkmake:v0.3.2
ACTIONLINT_IMAGE := rhysd/actionlint:1.7.12
ACT_RUNNER_IMAGE := catthehacker/ubuntu:act-24.04
HADOLINT_IMAGE := hadolint/hadolint:v2.15.1
REDIS_IMAGE := redis:8.10.3-alpine3.23
APP_IMAGE := $(APP_NAME)

VERSIONS_SCRIPT_PATH := scripts/versions.sh
HEALTHCHECK_SCRIPT_PATH := scripts/healthcheck.sh
CI_WORKFLOW_PATH := .github/workflows/ci.yml

SERVICE ?=

export

.PHONY: \
	history \
	versions \
	check \
	dry-run \
	shell-check \
	py-format \
	py-format-check \
	py-lint \
	py-lint-fix \
	py-imports-fix \
	py-typecheck \
	py-test \
	docker-lint \
	compose-lint \
	compose-config \
	ci-lint \
	ci-run \
	uvicorn-run \
	test-index \
	test-visits \
	test-visits-persistence \
	healthcheck \
	docker-network-create \
	docker-network-rm \
	docker-volume-rm \
	docker-build \
	docker-run \
	docker-stop \
	docker-rm \
	compose-build \
	compose-up \
	compose-up-wait \
	compose-down \
	compose-reset \
	compose-logs \
	compose-logs-app \
	compose-ps \
	compose-tests \
	checks \
	formats \
	build \
	up \
	test \
	down

history:
	git log --oneline --graph --all --decorate

versions:
	@test -f "$(VERSIONS_SCRIPT_PATH)" || { \
		echo "Script not found: $(VERSIONS_SCRIPT_PATH)" >&2; \
		exit 1; \
	}
	@if [ ! -x "$(VERSIONS_SCRIPT_PATH)" ]; then \
		echo "chmod +x $(VERSIONS_SCRIPT_PATH)"; \
		chmod +x "$(VERSIONS_SCRIPT_PATH)"; \
	fi
	"$(VERSIONS_SCRIPT_PATH)"

check:
	docker run --rm \
		--volume $(CHECKMAKE_VOLUME) \
		--volume $(CHECKMAKE_INI_VOLUME) \
		--workdir $(CHECKMAKE_WORKDIR) \
		$(CHECKMAKE_IMAGE)

dry-run:
	$(MAKE) --dry-run --warn-undefined-variables history > /dev/null

shell-check:
	@test -n "$(SCRIPT)" || { \
		echo "Usage: make shell-check SCRIPT=path/to/script.sh" >&2; \
		exit 1; \
	}
	@test -f "$(SCRIPT)" || { \
		echo "Script not found: $(SCRIPT)" >&2; \
		exit 1; \
	}
	bash -n "$(SCRIPT)"
	shellcheck "$(SCRIPT)"

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
	docker run --rm --interactive \
		$(HADOLINT_IMAGE) < Dockerfile

compose-lint:
	uv run compose-lint

compose-config:
	$(COMPOSE) config --quiet

ci-lint:
	docker run --rm \
		--volume $(ACTIONLINT_VOLUME) \
		--workdir $(ACTIONLINT_WORKDIR) \
		$(ACTIONLINT_IMAGE) \
		-color

ci-run:
	act push \
		-W $(CI_WORKFLOW_PATH) \
		-j checks \
		-P ubuntu-24.04=$(ACT_RUNNER_IMAGE)

uvicorn-run:
	uv run uvicorn app.main:app \
		--reload \
		--host $(APP_HOST) \
		--port $(APP_PUBLIC_PORT)

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
	@test -f "$(HEALTHCHECK_SCRIPT_PATH)" || { \
		echo "Script not found: $(HEALTHCHECK_SCRIPT_PATH)" >&2; \
		exit 1; \
	}
	@if [ ! -x "$(HEALTHCHECK_SCRIPT_PATH)" ]; then \
		echo "chmod +x $(HEALTHCHECK_SCRIPT_PATH)"; \
		chmod +x $(HEALTHCHECK_SCRIPT_PATH); \
	fi
	@test -n "$(URL)" || { \
		echo "Usage: make healthcheck URL=http://127.0.0.1:8080" >&2; \
		exit 1; \
	}
	"$(HEALTHCHECK_SCRIPT_PATH)" "$(URL)"

docker-network-create:
	docker network create $(APP_NETWORK_NAME)

docker-network-rm:
	docker network rm $(APP_NETWORK_NAME)

docker-volume-rm:
	docker volume rm $(REDIS_VOLUME_NAME)

docker-build:
	docker build \
		--build-arg APP_PORT=$(APP_PORT) \
		--tag $(APP_IMAGE) \
		.

docker-run:
ifeq ($(SERVICE),app)
	$(MAKE) docker-build
	docker run --detach \
		--name $(APP_NAME) \
		--env-file .env \
		--network $(APP_NETWORK_NAME) \
		--publish $(APP_PUBLIC_PORT):$(APP_PORT) \
		$(APP_IMAGE)
else ifeq ($(SERVICE),redis)
	docker run --detach \
		--name $(REDIS_NAME) \
		--network $(APP_NETWORK_NAME) \
		--volume $(REDIS_VOLUME) \
		$(REDIS_IMAGE) \
		redis-server --appendonly yes
else
	echo "Usage: make docker-run SERVICE=<app|redis>" >&2
	exit 1
endif

docker-stop:
ifeq ($(SERVICE),app)
	docker stop $(APP_NAME)
else ifeq ($(SERVICE),redis)
	docker stop $(REDIS_NAME)
else
	echo "Usage: make docker-stop SERVICE=<app|redis>" >&2
	exit 1
endif

docker-rm:
ifeq ($(SERVICE),app)
	docker rm --force $(APP_NAME)
else ifeq ($(SERVICE),redis)
	docker rm --force $(REDIS_NAME)
else
	echo "Usage: make docker-rm SERVICE=<app|redis>" >&2
	exit 1
endif

compose-build:
	$(COMPOSE) build

compose-up:
	$(COMPOSE) up --detach --build

compose-up-wait:
	$(COMPOSE) up --detach --build --wait

compose-down:
	$(COMPOSE) down --remove-orphans

compose-reset:
	$(COMPOSE) down --remove-orphans --volumes
	$(MAKE) compose-up

compose-logs:
	$(COMPOSE) logs --follow

compose-logs-app:
	$(COMPOSE) logs --follow app

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
	$(MAKE) healthcheck URL="$(APP_URL):$(APP_PUBLIC_PORT)"; \
	$(MAKE) test-visits-persistence SAVED_VISITS="$$VISITS"

checks:
	$(MAKE) check
	$(MAKE) dry-run
	$(MAKE) shell-check SCRIPT=$(VERSIONS_SCRIPT_PATH)
	$(MAKE) shell-check SCRIPT=$(HEALTHCHECK_SCRIPT_PATH)
	$(MAKE) py-format-check
	$(MAKE) py-lint
	$(MAKE) py-typecheck
	$(MAKE) py-test
	$(MAKE) docker-lint
	$(MAKE) compose-lint
	$(MAKE) compose-config
	$(MAKE) ci-lint
	$(MAKE) compose-tests

formats:
	$(MAKE) py-format
	$(MAKE) py-lint-fix
	$(MAKE) py-typecheck

build:
	$(MAKE) compose-build

up:
	$(MAKE) compose-up

test:
	$(MAKE) py-test
	$(MAKE) compose-tests

down:
	$(MAKE) compose-down
