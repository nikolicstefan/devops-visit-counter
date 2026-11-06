.PHONY: shellcheck versions

VERSIONS_SCRIPT := scripts/versions.sh

shellcheck:
	@test -n "$(SCRIPT)" || { \
		echo "Usage: make shellcheck SCRIPT=path/to/script.sh" >&2; \
		exit 1; \
	}
	@test -f "$(SCRIPT)" || { \
		echo "Script not found: $(SCRIPT)" >&2; \
		exit 1; \
	}
	@echo "Checking bash syntax: $(SCRIPT)"
	@bash -n "$(SCRIPT)"
	@echo "Running ShellCheck: $(SCRIPT)"
	@shellcheck "$(SCRIPT)"

versions:
	@test -f "$(VERSIONS_SCRIPT)" || { echo "Script not found: $(VERSIONS_SCRIPT)" >&2; exit 1; }
	@if [ ! -x "$(VERSIONS_SCRIPT)" ]; then \
		echo "Adding execute permission to $(VERSIONS_SCRIPT)"; \
		chmod +x "$(VERSIONS_SCRIPT)"; \
	fi
	@./$(VERSIONS_SCRIPT)
