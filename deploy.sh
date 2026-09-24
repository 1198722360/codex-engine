#!/bin/bash

set -e

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$SCRIPT_DIR"
export CODEX_ENGINE_DEPLOY_DIR="$SCRIPT_DIR"
mkdir -p account-volumes

# Versions before the single-init layout created a short-lived
# `engine-image` Compose container. Remove only that obsolete container before
# starting the current graph; the label filters leave volumes and all runtime
# containers untouched.
while IFS= read -r legacy_container; do
  if [[ -n "$legacy_container" ]]; then
    docker rm -f "$legacy_container"
  fi
done < <(
  docker ps -aq \
    --filter label=com.docker.compose.project=codex-engine-public \
    --filter label=com.docker.compose.service=engine-image
)

docker compose pull
docker pull ghcr.io/1198722360/codex-engine-engine:latest
docker compose up -d --remove-orphans
