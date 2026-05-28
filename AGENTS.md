# AGENTS.md

Guidance for AI agents working in this repository.

## Project Snapshot

ezBookkeeping is a self-hosted personal finance application. The backend is Go, the frontend is Vue 3 with TypeScript, Vite, Vuetify for desktop UI, and Framework7 for mobile UI. The app also exposes API/MCP tooling for account, transaction, tag, category, and exchange-rate operations.

Important entry points:

- `ezbookkeeping.go`: CLI entry point, wired through `urfave/cli/v3`.
- `cmd/`: CLI commands and server startup.
- `pkg/api/`: HTTP API handlers.
- `pkg/services/`: business/service layer.
- `pkg/models/`: request/response and domain models.
- `pkg/converters/`: import/export parsers for finance formats.
- `pkg/mcp/`: MCP tool handlers.
- `src/desktop-main.ts`, `src/mobile-main.ts`, `src/index-main.ts`: frontend app entry points.
- `src/views/desktop/` and `src/views/mobile/`: platform-specific pages.
- `src/views/base/` and `src/components/base/`: shared page/component logic.
- `src/core/`, `src/lib/`, `src/stores/`, `src/models/`: frontend core logic, helpers, Pinia stores, and DTOs.
- `src/locales/` and `pkg/locales/`: frontend and backend localization.
- `conf/ezbookkeeping.ini`: default server configuration.
- `skills/ezbookkeeping/`: local API tool skill and scripts.

## First Steps

Before editing, inspect the relevant files with `rg`/`rg --files` and read current code paths. Do not rely on remembered paths or assumptions. Keep changes scoped to the requested behavior.

Check the working tree before and after edits:

```bash
git status --short
```

Do not revert unrelated user changes. Do not bump versions, create releases, push, tag, or publish unless explicitly requested in the current turn.

## Fork Workflow

This repository is a personal fork of upstream `mayswind/ezbookkeeping`.

Long-running branches:

- `main`: clean upstream sync branch. Keep it aligned with `upstream/main`; do not add personal features here.
- `dev`: personal fork mainline. Daily development, personal changes, and self-hosted releases happen here.

Temporary branches:

- `pr/<topic>`: only for focused changes that will be proposed to upstream.

Personal release tags are created directly from `dev` after validation. Use this format:

```text
vX.Y.Z-han.YYYYMMDD.N
```

Example:

```text
v1.5.1-han.20260528.1
```

Do not maintain a long-running `release` branch unless the project later needs multiple personal release lines.

## NAS Deployment Contract

The production NAS has its own Docker Compose file, `ezbookkeeping.ini`, and MySQL configuration. Treat those as private operational assets outside this repository.

The expected self-hosted upgrade path is image-only:

```yaml
image: hanops/ezbookkeeping:vX.Y.Z-han.YYYYMMDD.N
```

Do not ask the user to edit NAS Compose, `ezbookkeeping.ini`, MySQL settings, volumes, ports, or secrets for a normal fork release. Only require configuration changes when upstream changes its required configuration or when this fork introduces a feature that explicitly needs new configuration. When that happens, document the exact config delta and keep it separate from the image replacement step.

## Build And Test Commands

Frontend:

```bash
npm run test
npm run lint
npm run build
```

Backend:

```bash
go test ./...
go vet ./...
```

Project build script:

```bash
./build.sh backend
./build.sh frontend
./build.sh package -o ezbookkeeping.tar.gz
```

Personal release precheck:

```bash
scripts/check-release-ready.sh vX.Y.Z-han.YYYYMMDD.N
```

Local service smoke test:

```bash
scripts/smoke-local-test.sh
```

The build script runs dependency install/get, lint, tests, and build steps unless `--no-lint` or `--no-test` is passed. Use those flags only when there is a clear reason and report it.

Some exchange-rate tests skip third-party API checks in CI unless `BUILD_PIPELINE=1` and `CHECK_3RD_API=1` are set. `SKIP_TESTS` can be used by the build scripts to pass Go's `-skip` pattern.

For narrow changes, run the smallest relevant test first, then broaden if the touched area is shared or risky.

## Running Locally

For a fresh local test environment, run:

```bash
./scripts/bootstrap-local-test.sh
```

For day-to-day isolated local testing, source the project-local environment:

```bash
. ./scripts/local-test-env.sh
```

`local-test-env.sh` must be sourced, not executed directly, because it exports variables into the current shell. This keeps Go caches, npm cache, temp files, the local SQLite database, logs, storage, and the Python virtual environment inside `.local-test/`. The directory is ignored by Git.

Frontend development server:

```bash
npm run serve
```

Backend web server after building:

```bash
./ezbookkeeping server run
```

The default config listens on port `8080`, uses SQLite at `data/ezbookkeeping.db`, and serves static files from `public` unless overridden in `conf/ezbookkeeping.ini`.

The prepared local test config uses:

```bash
"$EBK_BINARY" --conf-path "$EBK_CONF_PATH" server run
```

The local seed account is `localtest` / `localtest123`, with runtime data under `.local-test/`.
Run `scripts/smoke-local-test.sh` after bootstrap or backend changes to verify the local server reaches `/healthz.json`.

## Code Style

Follow `.editorconfig`:

- General files use UTF-8, final newline, trimmed trailing whitespace, 4-space indentation.
- Go files use tabs via `gofmt`.
- `package.json` uses 2-space indentation.

Go:

- Run `gofmt` on edited Go files.
- Keep package boundaries aligned with the existing layers: API handlers in `pkg/api`, business logic in `pkg/services`, domain/data types in `pkg/models`, reusable utilities in `pkg/utils` or the existing relevant package.
- Prefer existing error types in `pkg/errs` and validation helpers in `pkg/validators`.
- Add or update tests near the changed package when behavior changes.

Frontend:

- TypeScript is strict; avoid unused locals and implicit returns.
- Use the `@/` alias for `src` imports when matching existing code.
- Keep desktop UI in Vuetify patterns and mobile UI in Framework7 patterns.
- Put shared logic in existing `base`, `core`, `lib`, or store modules only when it is truly shared.
- Use existing localization patterns instead of hard-coded user-visible strings.

## API, MCP, And Tooling

The project contains an ezBookkeeping skill at `skills/ezbookkeeping/SKILL.md`.

Linux/macOS helper script:

```bash
sh skills/ezbookkeeping/scripts/ebktools.sh list
sh skills/ezbookkeeping/scripts/ebktools.sh help <command>
sh skills/ezbookkeeping/scripts/ebktools.sh [global-options] <command> [command-options]
```

The tool expects:

- `EBKTOOL_SERVER_BASEURL`
- `EBKTOOL_TOKEN`

These may be set in the environment or a user-home `.env`. Do not commit tokens or local secrets.

## Localization

When adding or changing user-visible frontend strings, update the relevant files in `src/locales/`. When changing backend locale strings, check `pkg/locales/`. Preserve existing locale keys and naming style where possible.

## Security And Data Safety

- Never commit secrets, API tokens, generated databases, logs, or local storage.
- Never commit `.local-test/`, NAS Docker Compose files, real database dumps, or private deployment config.
- Keep `.dockerignore` aligned with `.gitignore` so ignored local data is not sent to Docker build contexts.
- Treat `conf/ezbookkeeping.ini` as default/example configuration; avoid putting private local values there.
- Be careful with data import/export code in `pkg/converters/`; many tests use files under `testdata/`.
- Avoid destructive database, storage, Git, Docker, or release actions unless the user explicitly asks for that exact action.

## Verification Reporting

In final responses, say exactly what was changed and which commands were run. If a command was not run, do not imply it passed. Use concise wording and include relevant failures or skipped checks.
