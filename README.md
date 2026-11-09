# Visit Counter
[![CI](https://github.com/nikolicstefan/devops-visit-counter/actions/workflows/ci.yml/badge.svg)](https://github.com/nikolicstefan/devops-visit-counter/actions/workflows/ci.yml)

## Architecture

The application is containerized using Docker and orchestrated
with Docker Compose.

```text
                 HTTP Client
                      |
                      v
              localhost:8080
                      |
                      v
               Docker Compose
                      |
             +--------+--------+
             |                 |
             v                 v
       FastAPI App           Redis
       (app:8000)       (redis:6379)
             |                 |
             |                 v
             |            redis-data
             |              volume
             |
             v
        Request Logging
           (stdout)
```

## API

### Available Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/` | Returns a greeting and the application hostname |
| GET | `/visits` | Increments and returns the persistent visit counter |

#### GET /

Example response:

```json
{
  "message": "Hello DevOps",
  "host": "application-hostname"
}
```

#### GET /visits

Increments the Redis-backed visit counter and returns its current value.

Example response:

```json
{
  "visits": 42
}
```

Each HTTP request is logged to standard output (stdout).

## Configuration

### Environment Configuration

Application configuration is managed through environment variables.

The `.env.example` file provides the required configuration:

| Variable | Description | Example |
|---|---|---|
| `APP_PORT` | Application listening port | `8000` |
| `REDIS_HOST` | Redis service hostname | `redis` |
| `REDIS_PORT` | Redis service port | `6379` |

Create a local environment file:

```bash
cp .env.example .env
```

The `.env` file is excluded from Git. Only `.env.example` is committed.
Environment variables are loaded and validated using Pydantic Settings.

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

## Docker Containerization

The application is packaged into a Docker image based on the official
Python slim image.

### Dockerfile

The Dockerfile uses uv for dependency installation and takes advantage
of Docker BuildKit caching.

Key implementation decisions:

- Python dependencies are installed before application source code
  is copied, allowing dependency layers to be reused.
- Dependencies are installed from the locked `uv.lock` file.
- Development dependencies are excluded from the production image.
- The application runs as a non-root user.
- Python output is unbuffered to make application logs available
  immediately through Docker.
- The official uv image is used to provide the uv executable during
  the build without retaining it in the final application image.

### Building the Image

Build the application image:

```bash
docker build -t visit-counter .
```

Run the container independently:

```bash
docker run --rm -p 8000:8000 visit-counter
```

### Compose Configuration

The Compose configuration currently defines a single application service.

- Host port `8000` is mapped to container port `8000`.
- The container uses the restart policy `unless-stopped`.
- A healthcheck periodically verifies that the application responds
  successfully to HTTP requests.
- The healthcheck uses Python's standard library, avoiding additional
  packages in the production image.

The application container is considered healthy when its HTTP endpoint
responds successfully.

### Running with Docker Compose

Docker Compose is used to build and run the application container.

Make sure the environment file is created:

```bash
test -f .env
```

Validate the Compose configuration:

```bash
docker compose config --quiet
```

Build and start the application:

```bash
docker compose up -d --build --wait --wait-timeout 60
```

Check container status:

```bash
docker compose ps --all
```

The application is available at:

**http://localhost:8000/**

Test the API:

```bash
curl --fail-with-body --show-error http://localhost:8000/
curl --fail-with-body --show-error http://localhost:8000/visits/
```

View application logs:

```bash
docker compose logs -f app
```

Stop the environment:

```bash
docker compose down --remove-orphans
```

### Redis Persistence

Redis uses a named Docker volume and Append Only File (AOF) persistence.

The volume preserves counter data when containers are stopped and recreated.

To verify persistence:

```bash
curl --fail-with-body --show-error http://localhost:8080/visits
docker compose down
docker compose up -d
curl --fail-with-body --show-error http://localhost:8080/visits
```

The counter continues from its previously stored value.

**Note:** `docker compose down -v` removes named volumes and permanently deletes the stored counter data.

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

## CI Pipeline

GitHub Actions is used for continuous integration.

The workflow is defined in `.github/workflows/ci.yml`.

### Triggers

- Push to any branch.
- Pull requests targeting `main`.

### Pipeline Checks

1. Check out the repository.
2. Create `.env` file from `.env.example`.
2. Set up Python and uv.
3. Install ShellCheck and project dependencies.
4. Validate Bash scripts using ShellCheck.
5. Check Python formatting with Ruff.
6. Run Ruff linting.
7. Run mypy type checking.
8. Run automated tests using pytest.
9. Lint the Dockerfile using Hadolint.
10. Validate the Docker Compose configuration.
11. Build the Docker image using Docker Compose.
12. Run smoke tests.

## Tools and AI Usage

**ChatGPT**, **Gemini** and **Claude** are used for technical explanations, architectural discussions, documentation, and troubleshooting.
