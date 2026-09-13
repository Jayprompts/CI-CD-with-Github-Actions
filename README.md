# Assignment 3 — CI/CD with GitHub Actions

A Bash CLI (`app/app.sh`) providing system info and host/port checks,
packaged in Docker, with a GitHub Actions pipeline that lints, tests, and
builds/smoke-tests the image on every push and pull request.

## Contents

- `app/app.sh` — CLI: `system-info`, `check-host <host>`, `check-port <host> <port>`, `help`.
- `scripts/lint.sh` — verifies required files exist and checks Bash syntax.
- `scripts/build.sh` — builds the Docker image and runs smoke tests.
- `tests/test.sh` — 10 tests covering all commands and input validation.
- `Dockerfile`, `compose.yaml`, `.dockerignore` — containerizes the CLI.
- `.github/workflows/ci.yml` — CI pipeline: validate → test → docker.
- `grade.sh` — instructor-supplied local grading script.

## Installation / Setup

Requires `bash` and Docker (Docker Desktop on Mac/Windows, Docker Engine on Linux).

```bash
git clone <this-repository-url>
cd assignment-3
chmod +x app/*.sh scripts/*.sh tests/*.sh
```

## Usage

**Run the CLI directly:**
```bash
./app/app.sh help
./app/app.sh system-info
./app/app.sh check-host example.com
./app/app.sh check-port example.com 443
```

**Build and run in Docker:**
```bash
docker build -t devops-tool .
docker run --rm devops-tool help
docker run --rm devops-tool system-info
```

**Exit codes:** `0` success, `1` operational/runtime failure (host unreachable,
port closed), `2` invalid command or invalid/missing input.

## Testing

```bash
./scripts/lint.sh     # required files + Bash syntax
./tests/test.sh       # 10 tests against app.sh
./scripts/build.sh    # Docker build + smoke tests (help, system-info, invalid command)
```

Or run everything the instructor will run:
```bash
chmod +x grade.sh
./grade.sh
```

## CI/CD Pipeline

`.github/workflows/ci.yml` runs on every `push` and `pull_request`, with
three jobs enforced in order via `needs:`:

1. **validate** — runs `scripts/lint.sh`
2. **test** — runs `tests/test.sh` (depends on `validate` succeeding)
3. **docker** — runs `scripts/build.sh` (depends on `test` succeeding)

### CI failure demonstration

To confirm the pipeline actually catches problems rather than just running
green by default, a branch (`demo/ci-failure`) was created with a
deliberately incorrect test assertion in `tests/test.sh` (expecting exit
code `0` instead of the correct `2` for an unknown command).

- **Failed run:** the `validate` job passed, `test` failed as expected, and
  `docker` did not run (blocked by its `needs: test` dependency):
  https://github.com/Jayprompts/CI-CD-with-Github-Actions/actions/runs/34729673166/job/103650032767

- **Fixed run:** after reverting the assertion to the correct expected exit
  code (`2`) and pushing again, all three jobs passed:
  https://github.com/Jayprompts/CI-CD-with-Github-Actions/actions/runs/34729893837/job/103650631300

This confirms the `needs:` chain genuinely enforces order — a failure in an
earlier stage prevents later stages from running, rather than every job
running independently regardless of outcome.