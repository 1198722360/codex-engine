#!/bin/bash

set -e

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$SCRIPT_DIR"
export CODEX_ENGINE_DEPLOY_DIR="$SCRIPT_DIR"
mkdir -p account-volumes

ENGINE_IMAGE="${CODEX_ENGINE_IMAGE:-ghcr.io/1198722360/codex-engine-engine:latest}"
ENGINE_VERSION="${CODEX_NATIVE_VERSION:-0.155.1}"
RELEASE_MANIFEST="$SCRIPT_DIR/manager-state/releases/${ENGINE_VERSION}.json"

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

# The public Compose file intentionally points at :latest, while the manager
# persists the platform-specific Engine config digest in its release manifest.
# Never replace that tag behind the manager's back: doing so makes init reject
# the deployment and, more importantly, bypasses the drain/replace/commit
# upgrade flow. On an existing deployment, restore the registered image tag
# from the local image store and let the controlled upgrade path change it.
registered_digest=""
if [[ -f "$RELEASE_MANIFEST" ]]; then
  registered_digest="$({ sed -nE 's/.*"image_digest"[[:space:]]*:[[:space:]]*"(sha256:[0-9a-f]{64})".*/\1/p' "$RELEASE_MANIFEST" || true; } | head -n 1)"
  if [[ ! "$registered_digest" =~ ^sha256:[0-9a-f]{64}$ ]]; then
    echo "public deployment failed: release manifest has no valid Engine image identity / 公开部署失败：发布清单没有有效的引擎镜像身份" >&2
    exit 1
  fi
fi

if [[ -n "$registered_digest" ]]; then
  current_digest="$(docker image inspect --format '{{.Id}}' "$ENGINE_IMAGE" 2>/dev/null || true)"
  if [[ "$current_digest" != "$registered_digest" ]]; then
    if ! docker image inspect "$registered_digest" >/dev/null 2>&1; then
      echo "Engine image ${registered_digest} is not present locally; run the controlled upgrade flow or restore that image before deploying / 引擎镜像 ${registered_digest} 不在本机，请先执行受控升级或恢复该镜像，再部署" >&2
      exit 1
    fi
    echo "Restoring registered Engine image ${registered_digest} for this deployment / 正在恢复本次部署登记的引擎镜像 ${registered_digest}"
    if ! docker tag "$registered_digest" "$ENGINE_IMAGE"; then
      echo "could not restore the registered Engine image tag / 无法恢复登记的引擎镜像标签" >&2
      exit 1
    fi
  fi
else
  docker pull "$ENGINE_IMAGE"
fi

docker compose up -d --remove-orphans
