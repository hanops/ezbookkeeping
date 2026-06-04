#!/bin/sh
CUR_DIR=$(dirname "$0");

# git-rev-sync requires a git repo to resolve commit hashes during vite build.
# .dockerignore excludes .git/, so initialise a minimal repo inside the build context.
if [ ! -d .git ]; then
  git init -q
  git config user.email "build@localhost"
  git config user.name "build"
  git add -A
  git commit -q -m "build" --allow-empty
fi

if [ -x "${CUR_DIR}/custom-frontend-pre-setup.sh" ]; then
  "${CUR_DIR}"/custom-frontend-pre-setup.sh
fi
