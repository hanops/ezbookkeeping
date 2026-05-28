#!/usr/bin/env sh

set -eu

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LOCAL_TEST_DIR="$ROOT_DIR/.local-test"
LOCAL_TEST_ENV="$ROOT_DIR/scripts/local-test-env.sh"
LOCAL_TEST_CONFIG_EXAMPLE="$ROOT_DIR/conf/ezbookkeeping.local-test.ini.example"
LOCAL_TEST_CONFIG="$LOCAL_TEST_DIR/ezbookkeeping.local.ini"
LOCAL_TEST_README="$LOCAL_TEST_DIR/README.md"
LOCAL_TEST_DOTENV="$LOCAL_TEST_DIR/.env"

TEST_USERNAME="${EBK_TEST_USERNAME:-localtest}"
TEST_PASSWORD="${EBK_TEST_PASSWORD:-localtest123}"
TEST_EMAIL="${EBK_TEST_EMAIL:-localtest@example.test}"
TEST_NICKNAME="${EBK_TEST_NICKNAME:-Local Test}"
TEST_CURRENCY="${EBK_TEST_CURRENCY:-USD}"
TEST_SERVER_BASEURL="${EBK_TEST_SERVER_BASEURL:-http://127.0.0.1:18080}"

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

if [ ! -d "$LOCAL_TEST_DIR/venv" ]; then
    python3 -m venv "$LOCAL_TEST_DIR/venv"
fi

if [ ! -f "$LOCAL_TEST_CONFIG" ]; then
    cp "$LOCAL_TEST_CONFIG_EXAMPLE" "$LOCAL_TEST_CONFIG"
fi

# shellcheck disable=SC1090
. "$LOCAL_TEST_ENV"

echo "Building local test binary at $EBK_BINARY"
go build -o "$EBK_BINARY" ezbookkeeping.go

echo "Initializing local test database"
"$EBK_BINARY" --conf-path "$EBK_CONF_PATH" --no-boot-log database update

created_user=0

if "$EBK_BINARY" --conf-path "$EBK_CONF_PATH" --no-boot-log userdata user-get --username "$TEST_USERNAME" >/dev/null 2>&1; then
    echo "Local test user \"$TEST_USERNAME\" already exists"
else
    echo "Creating local test user \"$TEST_USERNAME\""
    "$EBK_BINARY" --conf-path "$EBK_CONF_PATH" --no-boot-log userdata user-add \
        --username "$TEST_USERNAME" \
        --email "$TEST_EMAIL" \
        --nickname "$TEST_NICKNAME" \
        --password "$TEST_PASSWORD" \
        --default-currency "$TEST_CURRENCY" >/dev/null
    created_user=1
fi

if [ "$created_user" -eq 0 ] &&
    [ -f "$LOCAL_TEST_DOTENV" ] &&
    grep -q '^EBKTOOL_SERVER_BASEURL=' "$LOCAL_TEST_DOTENV" &&
    grep -q '^EBKTOOL_TOKEN=' "$LOCAL_TEST_DOTENV"; then
    echo "Local API token already exists in $LOCAL_TEST_DOTENV"
else
    echo "Creating local API token"
    token_output="$("$EBK_BINARY" --conf-path "$EBK_CONF_PATH" --no-boot-log userdata user-session-new --username "$TEST_USERNAME" --type api --expiresInSeconds 0)"
    token="$(printf '%s\n' "$token_output" | sed -n 's/^\[NewToken\] //p')"

    if [ -z "$token" ]; then
        echo "Failed to create local API token" >&2
        exit 1
    fi

    {
        printf 'EBKTOOL_SERVER_BASEURL=%s\n' "$TEST_SERVER_BASEURL"
        printf 'EBKTOOL_TOKEN=%s\n' "$token"
    } > "$LOCAL_TEST_DOTENV"
fi

cat > "$LOCAL_TEST_README" <<EOF
# Local Test Environment

This directory is intentionally ignored by Git.

## Activate

\`\`\`bash
. ./scripts/local-test-env.sh
\`\`\`

## Paths

- Config: \`.local-test/ezbookkeeping.local.ini\`
- Binary: \`.local-test/bin/ezbookkeeping\`
- SQLite database: \`.local-test/data/ezbookkeeping.db\`
- Logs: \`.local-test/log/\`
- Storage: \`.local-test/storage/\`
- Python virtual environment: \`.local-test/venv/\`
- Go/npm caches: \`.local-test/cache/\`

## Seed User

- Username: \`$TEST_USERNAME\`
- Password: \`$TEST_PASSWORD\`
- Default currency: \`$TEST_CURRENCY\`
- Local URL: \`$TEST_SERVER_BASEURL\`

## Useful Commands

\`\`\`bash
. ./scripts/local-test-env.sh
"\$EBK_BINARY" --conf-path "\$EBK_CONF_PATH" database update
"\$EBK_BINARY" --conf-path "\$EBK_CONF_PATH" server run
sh skills/ezbookkeeping/scripts/ebktools.sh list
\`\`\`
EOF

echo "Local test environment is ready."
echo "Next:"
echo "  . ./scripts/local-test-env.sh"
echo "  \"\$EBK_BINARY\" --conf-path \"\$EBK_CONF_PATH\" server run"
