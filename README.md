# Visit Counter

## Development Environment

### Prerequisites

- WSL2 with Ubuntu (recommended for Windows development)
- Git
- curl
- GNU Make
- uv
- shellcheck

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

### Verifying Installation

```bash
bash --version
code --version
git --version
curl --version
make --version
uv --version
shellcheck --version
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
| Git | 2.34.1 |
| curl | 7.81.0 |
| GNU Make | 4.3 |
| uv | 0.12.22 |
| ShellCheck | 0.8.0 |
| Project Python | 3.13.16 |
<!-- END AUTO-GENERATED: development-versions -->






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
