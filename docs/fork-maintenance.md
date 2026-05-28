# Fork Maintenance

This fork uses the simplest useful personal workflow.

## Branches

- `main`: clean upstream sync branch. Keep it aligned with `upstream/main`; do not add personal features here.
- `dev`: personal working branch. Daily development, personal changes, and self-hosted releases happen here.
- `pr/<topic>`: temporary branch used only when a change from `dev` is ready to send upstream as a focused PR.

Do not keep a long-running `release` branch. A personal release is the commit on `dev` that receives a release tag.

## Sync Upstream

```bash
git checkout main
git fetch upstream
git merge upstream/main
git checkout dev
git merge main
```

Resolve conflicts on `dev` in favor of preserving personal behavior unless the upstream change intentionally replaces it.

## Personal Release Tags

Tag personal releases from `dev` after tests pass.

Tag format:

```text
vX.Y.Z-han.YYYYMMDD.N
```

Example:

```bash
git checkout dev
git tag v1.5.1-han.20260528.1
```

Use the upstream/base app version for `X.Y.Z`, the build date for `YYYYMMDD`, and increment `N` for multiple builds on the same day.

## Upstream PRs

When a change in `dev` is worth proposing upstream, create a temporary PR branch:

```bash
git checkout -b pr/<short-topic> dev
```

Keep PR branches small and upstream-friendly:

- Include only the generic app change.
- Exclude personal deployment docs, NAS config, secrets, `.local-test/`, and fork-only release rules.
- Rewrite or split commits if needed before opening the PR.

Delete `pr/<topic>` after the PR is merged, rejected, or abandoned.

## Safety Rules

- Never commit `.local-test/`, real database dumps, NAS compose files, tokens, or private config.
- Keep the upstream remote fetchable but not pushable:

```bash
git remote set-url --push upstream DISABLED
```

- Before changing release or deployment files, check the current branch with:

```bash
git status --short --branch
```
