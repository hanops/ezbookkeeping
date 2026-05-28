# vX.Y.Z-han.YYYYMMDD.N

## Summary

- Base upstream version:
- Target image: `hanops/ezbookkeeping:vX.Y.Z-han.YYYYMMDD.N`
- Target platform: `linux/amd64`
- Release source branch: `dev`
- Release commit:

## NAS Deployment

- Deployment mode: image-only
- Compose change: replace image tag only
- `ezbookkeeping.ini` changes: none
- MySQL/PostgreSQL changes: none
- Volume/port/secret changes: none

If configuration changes are required, replace `none` with the exact key/value delta and explain why the image-only path is not enough.

## Validation

- `scripts/check-release-ready.sh vX.Y.Z-han.YYYYMMDD.N`
- `./scripts/bootstrap-local-test.sh`
- `scripts/smoke-local-test.sh`
- `go test ./...`
- `npm run test`
- `npm run lint`
- `docker buildx build --platform linux/amd64 -t hanops/ezbookkeeping:vX.Y.Z-han.YYYYMMDD.N --load .`
- NAS preflight with database/storage backup copies:

## Rollback

- Previous official image:
- Previous personal image, if any:
- Database backup:
- Storage backup:
- Rollback command or NAS Compose note:
