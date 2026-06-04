#!/usr/bin/env sh

set -eu

ALLOW_DIRTY=0
SKIP_DOCKER=0
EXPECTED_BRANCH="${EBK_RELEASE_BRANCH:-dev}"
TAG=""

show_help() {
    cat <<'EOF'
Check whether this fork is ready for a personal release.

Usage:
    scripts/check-release-ready.sh <tag> [--allow-dirty]

Tag format:
    vX.Y.Z-han.N

Example:
    scripts/check-release-ready.sh v1.6.0-han.2

Options:
    --allow-dirty    Permit uncommitted changes. Use only while testing this script.
    --skip-docker    Skip Docker/buildx availability checks.
    -h, --help       Show help.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --allow-dirty)
            ALLOW_DIRTY=1
            ;;
        --skip-docker)
            SKIP_DOCKER=1
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo "Unknown option: $1" >&2
            show_help >&2
            exit 2
            ;;
        *)
            if [ -n "$TAG" ]; then
                echo "Unexpected argument: $1" >&2
                show_help >&2
                exit 2
            fi
            TAG="$1"
            ;;
    esac
    shift
done

if [ -z "$TAG" ]; then
    echo "Release tag is required." >&2
    show_help >&2
    exit 2
fi

ROOT_DIR="$(git rev-parse --show-toplevel)"
cd "$ROOT_DIR"

current_branch="$(git branch --show-current)"
if [ "$current_branch" != "$EXPECTED_BRANCH" ]; then
    echo "Expected branch \"$EXPECTED_BRANCH\", got \"$current_branch\"." >&2
    exit 1
fi

if ! printf '%s\n' "$TAG" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+-han\.[0-9]+$'; then
    echo "Invalid tag format: $TAG" >&2
    echo "Expected: vX.Y.Z-han.N" >&2
    exit 1
fi

if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
    echo "Tag already exists: $TAG" >&2
    exit 1
fi

if [ "$ALLOW_DIRTY" -ne 1 ] && [ -n "$(git status --porcelain)" ]; then
    echo "Working tree is not clean. Commit or stash changes before release." >&2
    git status --short
    exit 1
fi

upstream_push_url="$(git remote get-url --push upstream 2>/dev/null || true)"
if [ "$upstream_push_url" != "DISABLED" ]; then
    echo "upstream push URL is not disabled: ${upstream_push_url:-<missing>}" >&2
    echo "Run: git remote set-url --push upstream DISABLED" >&2
    exit 1
fi

if [ "$SKIP_DOCKER" -ne 1 ]; then
    if ! command -v docker >/dev/null 2>&1; then
        echo "docker is not available in PATH." >&2
        exit 1
    fi

    if ! docker buildx version >/dev/null 2>&1; then
        echo "docker buildx is not available." >&2
        exit 1
    fi
fi

image="hanops/ezbookkeeping:$TAG"

cat <<EOF
Release precheck passed.

Branch: $current_branch
Tag:    $TAG
Image:  $image

Build command:
docker buildx build --platform linux/amd64 -t $image --load .
EOF
