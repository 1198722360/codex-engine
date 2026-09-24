#!/bin/bash

set -e

docker compose pull
docker pull ghcr.io/1198722360/codex-engine-engine:latest
docker compose up -d --remove-orphans
