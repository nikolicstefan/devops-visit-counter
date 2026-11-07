#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
README="$ROOT_DIR/README.md"

DEV_HEADING='### Tested Development Environment'
RUNTIME_HEADING='### Tested Runtime Environment'

if [[ ! -f "$README" ]]; then
    echo "README.md not found." >&2
    exit 1
fi

for heading in "$DEV_HEADING" "$RUNTIME_HEADING"; do
    if ! grep -Fqx "$heading" "$README"; then
        echo "Missing README heading: $heading" >&2
        exit 1
    fi
done

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

DEV_TABLE="$TMP_DIR/development.md"
RUNTIME_TABLE="$TMP_DIR/runtime.md"
UPDATED_README="$TMP_DIR/README.md"

first_line() {
    local output

    if ! output="$("$@" 2>/dev/null)"; then
        return 1
    fi

    output="${output%%$'\n'*}"
    output="${output//$'\r'/}"

    [[ -n "$output" ]] || return 1
    printf '%s' "$output"
}

value_or_na() {
    local output

    if output="$(first_line "$@")"; then
        printf '%s' "$output"
    else
        printf 'Not available'
    fi
}

row() {
    local label="$1"
    local value="${2//|/\\|}"

    printf '| %s | %s |\n' "$label" "$value"
}

# Host and operating system versions

windows_version() {
    # PowerShell variables must be expanded by PowerShell, not Bash.
    # shellcheck disable=SC2016,SC2288
    value_or_na powershell.exe -NoProfile -NonInteractive -Command \
        '$cv = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"; "$($cv.DisplayVersion) (build $($cv.CurrentBuild).$($cv.UBR))"'
}

wsl_version() {
    local output
    local line

    if ! output="$(
        powershell.exe -NoProfile -NonInteractive \
            -Command 'wsl.exe --version' 2>&1 |
            tr -d '\000'
    )"; then
        printf 'Not available'
        return
    fi

    while IFS= read -r line; do
        line="${line%$'\r'}"

        if [[ "$line" =~ ^WSL\ version:[[:space:]]*([0-9]+(\.[0-9]+)*)$ ]]; then
            printf '%s' "${BASH_REMATCH[1]}"
            return
        fi
    done <<< "$output"

    printf 'Not available'
}

wsl_kernel_version() {
    local output

    if output="$(first_line uname -r)"; then
        printf '%s\n' "$output" |
            sed -E 's/^([0-9]+(\.[0-9]+)+).*/\1/'
    else
        printf 'Not available'
    fi
}

ubuntu_version() {
    value_or_na lsb_release -ds |
        sed -E 's/^Ubuntu //'
}

bash_version() {
    value_or_na bash --version |
        sed -E 's/^GNU bash, version ([0-9.]+).*/\1/'
}

# Development tools

vscode_version() {
    if command -v code >/dev/null 2>&1; then
        value_or_na code --version
    elif command -v powershell.exe >/dev/null 2>&1; then
        value_or_na powershell.exe -NoProfile -NonInteractive -Command \
            'code --version | Select-Object -First 1'
    else
        printf 'Not available'
    fi
}

git_version() {
    value_or_na git --version |
        sed -E 's/^git version //'
}

curl_version() {
    value_or_na curl --version |
        sed -E 's/^curl ([^ ]+).*/\1/'
}

make_version() {
    value_or_na make --version |
        sed -E 's/^GNU Make //'
}

uv_version() {
    value_or_na uv --version |
        sed -E 's/^uv ([^ ]+).*/\1/'
}

shellcheck_version() {
    if ! command -v shellcheck >/dev/null 2>&1; then
        printf 'Not available'
        return
    fi

    local output

    output="$(shellcheck --version 2>/dev/null |
        sed -n 's/^version: //p' |
        head -n 1)" || true

    if [[ -n "$output" ]]; then
        printf '%s' "$output"
    else
        printf 'Not available'
    fi
}

project_python_version() {
    local output

    if output="$(
        cd "$ROOT_DIR" &&
        first_line uv run --no-sync python --version
    )"; then
        printf '%s\n' "$output" |
            sed -E 's/^Python //'
    else
        printf 'Not available'
    fi
}

# Runtime and container versions

docker_desktop_version() {
    value_or_na docker desktop version |
        sed -E 's/^Docker Desktop CLI plugin version: //'
}

docker_cli_version() {
    value_or_na docker --version |
        sed -E 's/^Docker version ([^, ]+).*/\1/'
}

docker_engine_version() {
    value_or_na docker version --format '{{.Server.Version}}'
}

docker_compose_version() {
    value_or_na docker compose version |
        sed -E 's/^Docker Compose version v?([^ ]+).*/\1/'
}

# Generate development environment table

{
    printf '| Component | Version |\n'
    printf '|---|---|\n'

    row 'Windows' "$(windows_version)"
    row 'WSL' "$(wsl_version)"
    row 'WSL Kernel' "$(wsl_kernel_version)"
    row 'Ubuntu' "$(ubuntu_version)"
    row 'Bash' "$(bash_version)"
    row 'Visual Studio Code' "$(vscode_version)"
    row 'Git' "$(git_version)"
    row 'curl' "$(curl_version)"
    row 'GNU Make' "$(make_version)"
    row 'uv' "$(uv_version)"
    row 'ShellCheck' "$(shellcheck_version)"

    if [[ -f "$ROOT_DIR/.python-version" &&
          -f "$ROOT_DIR/pyproject.toml" ]]; then
        row 'Project Python' "$(project_python_version)"
    fi
} > "$DEV_TABLE"

# Generate runtime environment table

{
    printf '| Component | Version |\n'
    printf '|---|---|\n'

    row 'Docker Desktop' "$(docker_desktop_version)"
    row 'Docker CLI' "$(docker_cli_version)"
    row 'Docker Engine' "$(docker_engine_version)"
    row 'Docker Compose' "$(docker_compose_version)"
} > "$RUNTIME_TABLE"

# Replace generated sections in README.md

awk -v dev_file="$DEV_TABLE" -v runtime_file="$RUNTIME_TABLE" '
function emit_file(path, line) {
    while ((getline line < path) > 0) print line
    close(path)
}

BEGIN {
    dev_begin = "<!-- BEGIN AUTO-GENERATED: development-versions -->"
    dev_end = "<!-- END AUTO-GENERATED: development-versions -->"

    runtime_begin = "<!-- BEGIN AUTO-GENERATED: runtime-versions -->"
    runtime_end = "<!-- END AUTO-GENERATED: runtime-versions -->"
}

{
    sub(/\r$/, "")

    if (skip == "dev") {
        if ($0 == dev_end) skip = ""
        next
    }

    if (skip == "runtime") {
        if ($0 == runtime_end) skip = ""
        next
    }

    if ($0 == dev_begin) {
        skip = "dev"
        next
    }

    if ($0 == runtime_begin) {
        skip = "runtime"
        next
    }

    if ($0 == "### Tested Development Environment") {
        print
        print ""
        print dev_begin
        emit_file(dev_file)
        print dev_end
        found_dev = 1
        next
    }

    if ($0 == "### Tested Runtime Environment") {
        print
        print ""
        print runtime_begin
        emit_file(runtime_file)
        print runtime_end
        found_runtime = 1
        next
    }

    print
}

END {
    if (!found_dev || !found_runtime) exit 1
}
' "$README" > "$UPDATED_README"

chmod --reference="$README" "$UPDATED_README"
mv "$UPDATED_README" "$README"

printf 'Updated version tables in README.md\n'
