#!/usr/bin/env sh

set -eu

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LOCAL_TEST_ENV="$ROOT_DIR/scripts/local-test-env.sh"
SMOKE_TIMEOUT="${EBK_SMOKE_TIMEOUT:-30}"

# shellcheck disable=SC1090
. "$LOCAL_TEST_ENV"

BASEURL="${EBK_SMOKE_BASEURL:-${EBKTOOL_SERVER_BASEURL:-http://127.0.0.1:18080}}"
HEALTH_URL="${BASEURL%/}/healthz.json"
SMOKE_LOG="$EBK_LOCAL_TEST_DIR/log/smoke-server.log"

if [ ! -x "$EBK_BINARY" ]; then
    echo "Local test binary is missing: $EBK_BINARY" >&2
    echo "Run: ./scripts/bootstrap-local-test.sh" >&2
    exit 1
fi

if [ ! -f "$EBK_CONF_PATH" ]; then
    echo "Local test config is missing: $EBK_CONF_PATH" >&2
    echo "Run: ./scripts/bootstrap-local-test.sh" >&2
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required for the smoke test." >&2
    exit 1
fi

if curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then
    echo "Smoke test passed. Existing local server is healthy: $HEALTH_URL"
    exit 0
fi

mkdir -p "$(dirname "$SMOKE_LOG")"

"$EBK_BINARY" --conf-path "$EBK_CONF_PATH" --no-boot-log server run >"$SMOKE_LOG" 2>&1 &
server_pid="$!"

cleanup() {
    if kill -0 "$server_pid" >/dev/null 2>&1; then
        kill "$server_pid" >/dev/null 2>&1 || true
        wait "$server_pid" >/dev/null 2>&1 || true
    fi
}

trap cleanup EXIT INT TERM

elapsed=0
while [ "$elapsed" -lt "$SMOKE_TIMEOUT" ]; do
    if curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then
        echo "Smoke test passed: $HEALTH_URL"
        exit 0
    fi

    if ! kill -0 "$server_pid" >/dev/null 2>&1; then
        echo "Local server exited before health check passed." >&2
        echo "Log: $SMOKE_LOG" >&2
        tail -n 80 "$SMOKE_LOG" >&2 || true
        exit 1
    fi

    sleep 1
    elapsed=$((elapsed + 1))
done

echo "Timed out waiting for local server health: $HEALTH_URL" >&2
echo "Log: $SMOKE_LOG" >&2
tail -n 80 "$SMOKE_LOG" >&2 || true
exit 1
