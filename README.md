# OpenCode Docker

A Docker image and launcher for running OpenCode in a project directory with a set of common development tools available.

## Build the image

From this directory, build the image expected by the launcher:

```sh
docker build -t opencode-docker .
```

The image is based on `ghcr.io/anomalyco/opencode`, with the version selected by the `OPENCODE_VERSION` build arg (default `2.1.2`), and installs Git, Python, PostgreSQL server and client tools, Node.js/npm, JDK 25, Maven, `jq`, `yq`, `fd`, `fzf`, build tools, Docker CLI, Podman, Herdr, and OpenSpec.

You normally do not need to build the image by hand: the launcher builds it automatically, and rebuilds it when a newer OpenCode version is published (see [Automatic updates](#automatic-updates)).

## Run OpenCode

Run the launcher from the project you want to work on:

```sh
/path/to/opencode-docker/opencode-docker
```

The launcher does not take arguments. The first time you run it for a project, it asks for a host port and saves it to `~/.config/docker-opencode/ports/<project>`. Every later run for that project reuses the saved port, so the project always gets the same URL. The container listens on a fixed internal port (`49374`), which the assigned host port is mapped to.

The launcher refuses to assign a port that is already assigned to another project. To change a project's port, edit or delete `~/.config/docker-opencode/ports/<project>` and run the launcher again.

The launcher starts a detached, temporary container in the background, mounts the current directory as the working directory, and runs OpenCode in server mode on the given port. It prints the container name, URL, and the commands to follow the logs or stop it:

```sh
docker logs -f opencode-<project>
docker stop opencode-<project>
```

The container is named `opencode-<project>`, where `<project>` is the project directory name. If a container with that name is already running, the launcher stops and removes it before starting the new one.

## Automatic updates

Each time the launcher runs, it queries the GitHub Container Registry for the newest published OpenCode version and compares it against the version the local `opencode-docker` image was built from (recorded in the `org.opencode-docker.base.version` image label). If the image is missing, or a newer version is available, the launcher pulls and rebuilds the image before starting OpenCode.

The detected version is passed to the build as the `OPENCODE_VERSION` build arg, so the `Dockerfile` does not need to be edited to pick up a new version.

Set `OPENCODE_DOCKER_NO_UPDATE=1` to skip the check and use the existing image as-is (useful offline). If the registry cannot be reached, the launcher prints a warning and continues with the existing image.

The image creates the `tine2k` account with UID `501` and GID `20`, so OpenCode and tools such as PostgreSQL `initdb` can resolve the user while files created in the mounted project use those numeric ownership values. Each container gets its own home directory under `~/.config/docker-opencode/projects/<project>` on the host, so its sessions, logs, cache, service state, and database are private to that project (see [Isolation and shared configuration](#isolation-and-shared-configuration)).

If `~/.ssh` exists on the host, the launcher mounts it read-only at `/home/tine2k/.ssh` so Git can use your SSH keys and `known_hosts` for GitHub pushes. When `SSH_AUTH_SOCK` points to an available host agent socket, the launcher forwards that socket as well, allowing use of keys loaded in the agent. If the SSH directory is missing, the launcher prints a warning; add your GitHub-authorized key to the host's `~/.ssh` and run the launcher again.

## Isolation and shared configuration

Each container is isolated: its home directory lives at `~/.config/docker-opencode/projects/<project>`, where `<project>` is the project directory name (the container is named `opencode-<project>`). Sessions, logs, cache, service state, and the SQLite database are private to that project. Because the key is the directory name, two different projects that share a directory name also share state.

The OpenCode configuration directory is shared by every container:

```text
host:      ~/.config/docker-opencode/config
container: /home/tine2k/.config/opencode
```

Everything OpenCode loads from `~/.config/opencode` — `opencode.json(c)`, `cli.json`, `agents/`, `commands/`, `skills/`, `plugins/` — is therefore identical in every container.

Saved provider credentials live in the per-project SQLite database and are **not** shared. Instead the launcher forwards provider credentials from the host environment: every host variable whose name ends in `_API_KEY` is passed to the container. List any additional variables in `OPENCODE_DOCKER_ENV` (space-separated). For variables that should stay set for one project, use a [per-project env file](#per-project-environment) instead:

```sh
ANTHROPIC_API_KEY=sk-ant-... \
OPENCODE_DOCKER_ENV="AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION" \
  /path/to/opencode-docker/opencode-docker
```

When upgrading from the previous layout, where `~/.config/docker-opencode` was mounted as the whole home directory, the launcher moves `~/.config/docker-opencode/.config/opencode` to `~/.config/docker-opencode/config` on first run so the shared configuration is preserved. Prior session data is not migrated.

## Per-project environment

`OPENCODE_DOCKER_ENV` applies to a single launch. To keep variables set for one project only, create a per-project env file:

```text
~/.config/docker-opencode/env/<project>
```

`<project>` is the project directory name, the same key used for ports and state. The file contains one `NAME=VALUE` per line; blank lines and lines starting with `#` are ignored, and values are passed literally (no shell quoting or expansion):

```sh
mkdir -p ~/.config/docker-opencode/env
cat > ~/.config/docker-opencode/env/my-app <<'EOF'
OPENCODE_DISABLE_FREE_MODELS=1
EOF
```

The file is read when the launcher starts the container and is not mounted into it. Variables defined there are applied after the host `*_API_KEY` and `OPENCODE_DOCKER_ENV` forwarding, so they override a forwarded value with the same name. Restart the project's container for changes to take effect.

## Herdr integration

If `~/.config/herdr/herdr.sock` exists on the host, the launcher mounts it into the container at `/run/herdr.sock` and sets `HERDR_SOCKET_PATH`. It also passes through the Herdr pane, tab, workspace, and environment variables when present. If the socket is missing, the launcher prints a warning and continues without the socket integration.

## Requirements

- Docker on the host
- Network access to `ghcr.io` for the automatic update check (optional; set `OPENCODE_DOCKER_NO_UPDATE=1` to skip it)
- The `opencode-docker` image is built automatically by the launcher, or manually as shown above
