# OpenCode Docker

A Docker image and launcher for running OpenCode in a project directory with a set of common development tools available.

## Build the image

From this directory, build the image expected by the launcher:

```sh
docker build -t opencode-docker .
```

The image is based on `ghcr.io/anomalyco/opencode:1.18.33` and installs Git, Python, PostgreSQL client tools, Node.js/npm, `jq`, `yq`, `fd`, `fzf`, build tools, Docker CLI, Podman, Herdr, and OpenSpec.

## Run OpenCode

Run the launcher from the project you want to work on:

```sh
/path/to/opencode-docker/opencode-docker
```

The launcher starts an interactive, temporary container, mounts the current directory as the working directory, and forwards any arguments to OpenCode. For example:

```sh
/path/to/opencode-docker/opencode-docker --help
```

The container runs using the host account named `tine2k`'s numeric UID and GID, so files created in the mounted project are owned by that account. Its home directory is backed by `~/.config/docker-opencode` on the host, where OpenCode configuration and state can persist between runs.

If `~/.ssh` exists on the host, the launcher mounts it read-only at `/home/tine2k/.ssh` so Git can use your SSH keys and `known_hosts` for GitHub pushes. When `SSH_AUTH_SOCK` points to an available host agent socket, the launcher forwards that socket as well, allowing use of keys loaded in the agent. If the SSH directory is missing, the launcher prints a warning; add your GitHub-authorized key to the host's `~/.ssh` and run the launcher again.

## Herdr integration

If `~/.config/herdr/herdr.sock` exists on the host, the launcher mounts it into the container at `/run/herdr.sock` and sets `HERDR_SOCKET_PATH`. It also passes through the Herdr pane, tab, workspace, and environment variables when present. If the socket is missing, the launcher prints a warning and continues without the socket integration.

## Requirements

- Docker on the host
- A host account named `tine2k`
- The `opencode-docker` image built locally as shown above
