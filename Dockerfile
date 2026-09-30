FROM ghcr.io/anomalyco/opencode:1.18.33

# Package installation needs root; the launcher supplies the host UID/GID at runtime.
USER root

RUN set -eux; \
    if command -v apk >/dev/null 2>&1; then \
        apk add --no-cache \
            bash curl git openssh-client python3 py3-pip \
            postgresql postgresql-client \
            nodejs npm \
            jq yq fd fzf \
            make build-base clang \
            docker-cli podman; \
    elif command -v apt-get >/dev/null 2>&1; then \
        apt-get update; \
        apt-get install -y --no-install-recommends ca-certificates curl gnupg; \
        install -d -m 0755 /etc/apt/keyrings; \
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
            | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg; \
        chmod a+r /etc/apt/keyrings/nodesource.gpg; \
        echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" \
            > /etc/apt/sources.list.d/nodesource.list; \
        apt-get update; \
        apt-get install -y --no-install-recommends \
            bash curl git openssh-client python3 python3-pip \
            postgresql postgresql-client \
            nodejs \
            jq yq fd-find fzf \
            make gcc g++ clang \
            docker.io podman; \
        rm -rf /var/lib/apt/lists/*; \
    elif command -v dnf >/dev/null 2>&1; then \
        dnf install -y \
            bash curl git openssh-clients python3 python3-pip \
            postgresql postgresql-server \
            nodejs npm \
            jq yq fd-find fzf \
            make gcc gcc-c++ clang \
            moby-engine podman; \
        dnf clean all; \
    elif command -v microdnf >/dev/null 2>&1; then \
        microdnf install -y \
            bash curl git openssh-clients python3 python3-pip \
            postgresql postgresql-server \
            nodejs npm \
            jq yq fd-find fzf \
            make gcc gcc-c++ clang \
            moby-engine podman; \
        microdnf clean all; \
    elif command -v yum >/dev/null 2>&1; then \
        yum install -y \
            bash curl git openssh-clients python3 python3-pip \
            postgresql postgresql-server \
            nodejs npm \
            jq yq fd-find fzf \
            make gcc gcc-c++ clang \
            moby-engine podman; \
        yum clean all; \
    else \
        echo 'No supported package manager found to install development tools' >&2; \
        exit 1; \
    fi; \
    if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then \
        ln -s "$(command -v fdfind)" /usr/local/bin/fd; \
    fi

RUN curl -fsSL https://herdr.dev/install.sh | sh

RUN npm install -g @fission-ai/openspec@latest
