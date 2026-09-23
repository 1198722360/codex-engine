# Codex Engine

This repository distributes the complete Linux arm64 runtime as two public container images: the Rust gateway with its Python management services and web UI, and the official Codex engine with its Python supervisor. MySQL and Redis are pulled by Compose. The Rust source is kept in a separate private repository; Python runtime files are included in the images.

Each runtime image is published in its own Docker Hub repository with `latest` and a shared UTC timestamp tag. The supplied `.env` selects the matching timestamp pair; Compose defaults to `latest` if those entries are removed. MySQL and Redis use ordinary version tags without digest suffixes.

## Deploy

Install Docker with Compose, then run from this directory:

```sh
./deploy.sh
docker compose ps
```

The web UI and API listen on `http://127.0.0.1:18183` by default. Change `GATEWAY_HOST_PORT` in `.env` before first use to choose another host port. The first run creates private credentials and state in Docker named volumes. No account is authorized automatically; add one through the web UI.

Read the generated web management password and client API key on the deployment host:

```sh
docker compose run --rm --no-deps --entrypoint cat gateway /run/bootstrap/management-token
docker compose run --rm --no-deps --entrypoint cat gateway /run/bootstrap/api-token
```

Treat both values as secrets. The `.env` file contains only public configuration and runtime image tags. The Compose project name is `codex-engine-public`; changing it later selects a different set of volumes.

`deploy.sh` is deliberately limited to pulling images and starting Compose. Re-running it preserves the volumes; the timestamp-tagged gateway and engine remain on the selected release pair. MySQL and Redis version tags are maintained upstream and may change when pulled again. In-place version changes and engine upgrades require the controlled drain and migration workflow; replacing runtime image tags while requests are active is outside this deployment command.

## Distribution terms

You may download and run the unmodified Codex Engine release images and binary for your own use. This grant does not include permission to modify or redistribute Codex Engine components. Bundled third-party software remains under its own licenses.

The earlier [v0.1.0 Release](https://github.com/1198722360/codex-engine/releases/tag/v0.1.0) contains only the standalone Rust gateway binary. The v0.2.2 runtime release is the complete deployable package described here.
