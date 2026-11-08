# Visit Counter
[![CI](https://github.com/nikolicstefan/devops-visit-counter/actions/workflows/ci.yml/badge.svg)](https://github.com/nikolicstefan/devops-visit-counter/actions/workflows/ci.yml)

## Architecture

The application is organized into separate modules for HTTP application setup and route definitions.

```text
                 HTTP Client
                      |
                      v
               FastAPI Application
                  (app/main.py)
                      |
               Request Logging
                   (stdout)
                      |
                      v
                  APIRouter
                (app/router.py)
                      |
                      v
                 JSON Response
```

## API

### Available Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/` | Returns a greeting and the application hostname |

#### GET /

Example response:

```json
{
  "message": "Hello DevOps",
  "host": "application-hostname"
}
```

The `host` field identifies the host on which the application is running.

Each HTTP request is logged to standard output (stdout).

## CI Pipeline

GitHub Actions is used for continuous integration.

The workflow is defined in `.github/workflows/ci.yml`.

### Triggers

- Push to any branch.
- Pull requests targeting `main`.

### Pipeline Checks

1. Checkout repository.
2. Set up Python and uv.
3. Install ShellCheck and project dependencies.
4. Validate Bash scripts using ShellCheck.
5. Check Python formatting with Ruff.
6. Run Ruff linting.
7. Run mypy type checking.
8. Run pytest.
9. Lint Dockerfile using Hadolint.

## Development Environment

### Prerequisites

- WSL2 with Ubuntu (recommended for Windows development)
- Docker Desktop (with WSL integration)
- Git
- curl
- GNU Make
- Shellcheck
- uv
- act

### Installing Development Tools

Install system packages:

```bash
sudo apt update
sudo apt install -y git curl make shellcheck
```

Install uv:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Restart the terminal or reload the shell configuration after installation.

Install act:

**https://nektosact.com/installation/**

### Verifying Installation

```bash
bash --version
code --version
docker --version
docker version
docker desktop version
git --version
curl --version
make --version
shellcheck --version
uv --version
act --version
```

### Tested Development Environment

<!-- BEGIN AUTO-GENERATED: development-versions -->

| Component | Version |
|---|---|
| Windows | 25H2 (build 26200.9711) |
| WSL | 2.1.5.0 |
| WSL Kernel | 5.15.146.1 |
| Ubuntu | 22.04.5 LTS |
| Bash | 5.1.16 |
| Visual Studio Code | 1.145.2 |
| Docker Desktop | 4.98.0 |
| Docker CLI | 29.9.2 |
| Docker Engine | 29.9.2 |
| Git | 2.34.1 |
| curl | 7.81.0 |
| GNU Make | 4.3 |
| ShellCheck | 0.8.0 |
| uv | 0.12.22 |
| act | 0.2.97 |
| Project Python | 3.13.16 |

<!-- END AUTO-GENERATED: development-versions -->

### Python Project Setup

The project uses Python 3.13, managed by uv.

The Python version is pinned in `.python-version`.

Install project dependencies:

```bash
uv sync --locked --dev
```

Dependencies are declared in `pyproject.toml` and locked in `uv.lock`.

### Running Locally

Start the development server:

```bash
make run
```

The application is available at:

http://127.0.0.1:8000/

### Code Quality and Testing

The project uses Ruff for linting and formatting, mypy for static type checking, and pytest for automated testing.

Format the source code:

```bash
make formats
```

Run all local CI checks:

```bash
make checks
```

The checks include:

- Bash syntax validation and ShellCheck
- Ruff formatting validation
- Ruff linting
- mypy type checking
- pytest
- Hadolint linting
- actionlint linting

## Runtime Environment

### Prerequisites

- Docker Desktop (Windows/macOS), or Docker Engine and Docker Compose plugin (Linux)

### Installation

**Windows**

Install Docker Desktop:

**https://docs.docker.com/desktop/setup/install/windows-install/**

Enable WSL integration for the Ubuntu distribution.

**Linux**

Install Docker Engine and Docker Compose plugin:

**https://docs.docker.com/engine/install/**

### Verifying Installation

```bash
docker --version
docker version
docker compose version
docker desktop version
```

### Tested Runtime Environment

<!-- BEGIN AUTO-GENERATED: runtime-versions -->

| Component | Version |
|---|---|
| Docker Desktop | 4.98.0 |
| Docker CLI | 29.9.2 |
| Docker Engine | 29.9.2 |
| Docker Compose | 5.6.1 |

<!-- END AUTO-GENERATED: runtime-versions -->

## Tools and AI Usage

**ChatGPT**, **Gemini** and **Claude** are used for technical explanations, architectural discussions, documentation, and troubleshooting.
