#!/usr/bin/env sh

# Source this file before local test setup so caches and runtime files stay
# inside the repository instead of the operating-system user directories.

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LOCAL_TEST_DIR="$ROOT_DIR/.local-test"

mkdir -p \
    "$LOCAL_TEST_DIR/bin" \
    "$LOCAL_TEST_DIR/cache/go-build" \
    "$LOCAL_TEST_DIR/cache/go-mod" \
    "$LOCAL_TEST_DIR/cache/gopath" \
    "$LOCAL_TEST_DIR/cache/npm" \
    "$LOCAL_TEST_DIR/data" \
    "$LOCAL_TEST_DIR/log" \
    "$LOCAL_TEST_DIR/storage" \
    "$LOCAL_TEST_DIR/tmp"

export EBK_LOCAL_TEST_DIR="$LOCAL_TEST_DIR"
export EBK_CONF_PATH="$LOCAL_TEST_DIR/ezbookkeeping.local.ini"
export EBK_BINARY="$LOCAL_TEST_DIR/bin/ezbookkeeping"

export GOCACHE="$LOCAL_TEST_DIR/cache/go-build"
export GOMODCACHE="$LOCAL_TEST_DIR/cache/go-mod"
export GOPATH="$LOCAL_TEST_DIR/cache/gopath"
export NPM_CONFIG_CACHE="$LOCAL_TEST_DIR/cache/npm"
export npm_config_cache="$LOCAL_TEST_DIR/cache/npm"
export TMPDIR="$LOCAL_TEST_DIR/tmp"

if [ -f "$LOCAL_TEST_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    . "$LOCAL_TEST_DIR/.env"
    set +a
fi

if [ -d "$LOCAL_TEST_DIR/venv/bin" ]; then
    PATH="$LOCAL_TEST_DIR/venv/bin:$PATH"
fi

export PATH
