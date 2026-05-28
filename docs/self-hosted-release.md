# Self-Hosted Release

Personal Docker images are built on a separate development machine and deployed to the NAS through Docker Compose.

The NAS production environment owns its own Docker Compose file, `ezbookkeeping.ini`, MySQL settings, volumes, ports, and secrets. A normal personal release must be deployable by replacing only the Docker image tag. Configuration changes are exceptional and must be called out explicitly.

## Image Convention

- Image name: `hanops/ezbookkeeping`
- Target platform: `linux/amd64`
- Tag format: `vX.Y.Z-han.YYYYMMDD.N`
- Example tag: `v1.5.1-han.20260528.1`

Build example:

```bash
scripts/check-release-ready.sh v1.5.1-han.20260528.1
docker buildx build --platform linux/amd64 -t hanops/ezbookkeeping:v1.5.1-han.20260528.1 --load .
```

The precheck verifies the current branch, tag format, duplicate tag state, clean working tree, disabled upstream push URL, and Docker buildx availability.
On a machine without Docker, use `--skip-docker` only for the non-Docker parts of the precheck.

Use `docs/release-notes/TEMPLATE.md` for each personal release. The release note must explicitly say whether the deployment is image-only and whether `ezbookkeeping.ini`, database settings, volumes, ports, or secrets changed.

## Before Switching NAS

Back up the current production state:

- MySQL/Postgres database dump.
- Current Docker Compose file and `.env`.
- ezBookkeeping config files.
- Storage directory used for transaction pictures and uploaded files.
- Current official image tag, for rollback.

Do not change volume mappings, ports, database connection settings, secrets, or app config during a normal image switch.

Only edit NAS Compose, `ezbookkeeping.ini`, or MySQL settings when one of these is true:

- Upstream changes required configuration for the version being adopted.
- This fork adds or changes a feature that explicitly requires a new config key or runtime setting.
- A preflight test shows the existing production config is incompatible with the new image.

When config changes are required, document them as a separate migration note for that release. Keep the default deployment step image-only.

Keep these upstream deployment rules in mind:

- The official container uses `/ezbookkeeping/conf/ezbookkeeping.ini`, `/ezbookkeeping/data`, `/ezbookkeeping/log`, and `/ezbookkeeping/storage` as its default runtime paths.
- The container runs as UID/GID `1000:1000`, so mounted log and storage paths must be writable by that user.
- Production deployments should use MySQL or PostgreSQL rather than SQLite.
- Configuration can be supplied by mounting a config file, setting `EBK_CONF_PATH`, or using `EBK_{SECTION}_{OPTION}` environment variables.
- Secret values can be loaded from files with `EBKCFP_{SECTION}_{OPTION}`; use this for database passwords or secret keys when the NAS supports file-based secrets.
- Production must set a strong `EBK_SECURITY_SECRET_KEY`. Also verify `EBK_SERVER_DOMAIN` and `EBK_SERVER_ROOT_URL`, especially behind a reverse proxy or subpath.

## Preflight Test

Before switching production, start a temporary environment using:

- A database backup copy.
- A storage backup copy.
- The new personal image tag.

Verify:

- `/healthz.json` returns success.
- Login works.
- Accounts, transactions, categories, tags, and attachments load.
- Import/export still works.
- API/MCP tokens work if they are used by your workflow.

## Switch In Docker Compose

For the normal path, only replace the image tag:

```yaml
image: hanops/ezbookkeeping:v1.5.1-han.20260528.1
```

Keep the existing Compose file structure, `ezbookkeeping.ini`, MySQL connection, volumes, ports, environment variables, and secrets unchanged. Then restart the service with the existing Compose workflow.

## Rollback

If the new image fails:

1. Stop the personal image container.
2. Change the Compose image back to the previous official `mayswind/ezbookkeeping:<tag>`.
3. Restore the pre-switch database dump if the app migrated data in an incompatible way.
4. Restore storage/config backups only if they were changed during testing.

Keep rollback notes with the release tag so each NAS deployment has a known return path.
