FROM ghcr.io/anomalyco/opencode:1.18.34

# Package installation needs root.
USER root

RUN set -eux; \
    if command -v apk >/dev/null 2>&1; then \
        apk add --no-cache \
            bash curl git openssh-client python3 py3-pip \
            postgresql postgresql-client \
            setpriv \
            nodejs npm \
            jq yq fd fzf \
            make build-base clang \
            docker-cli podman chromium; \
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
            util-linux \
            nodejs \
            jq yq fd-find fzf \
            make gcc g++ clang \
            docker.io podman; \
        rm -rf /var/lib/apt/lists/*; \
    elif command -v dnf >/dev/null 2>&1; then \
        dnf install -y \
            bash curl git openssh-clients python3 python3-pip \
            postgresql postgresql-server \
            util-linux \
            nodejs npm \
            jq yq fd-find fzf \
            make gcc gcc-c++ clang \
            moby-engine podman; \
        dnf clean all; \
    elif command -v microdnf >/dev/null 2>&1; then \
        microdnf install -y \
            bash curl git openssh-clients python3 python3-pip \
            postgresql postgresql-server \
            util-linux \
            nodejs npm \
            jq yq fd-find fzf \
            make gcc gcc-c++ clang \
            moby-engine podman; \
        microdnf clean all; \
    elif command -v yum >/dev/null 2>&1; then \
        yum install -y \
            bash curl git openssh-clients python3 python3-pip \
            postgresql postgresql-server \
            util-linux \
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

RUN set -eux; \
    if ! awk -F: '$3 == 20 { found = 1 } END { exit !found }' /etc/group; then \
        if awk -F: '$1 == "opencode-gid20" { found = 1 } END { exit !found }' /etc/group; then \
            echo 'Group name opencode-gid20 is already in use' >&2; \
            exit 1; \
        fi; \
        printf 'opencode-gid20:x:20:\n' >> /etc/group; \
    fi; \
    if awk -F: '$3 == 501 { found = 1 } END { exit !found }' /etc/passwd; then \
        if ! awk -F: '$1 == "tine2k" && $3 == 501 && $4 == 20 { found = 1 } END { exit !found }' /etc/passwd; then \
            echo 'UID 501 is already assigned to a different account' >&2; \
            exit 1; \
        fi; \
    else \
        if awk -F: '$1 == "tine2k" { found = 1 } END { exit !found }' /etc/passwd; then \
            echo 'Account name tine2k is already in use' >&2; \
            exit 1; \
        fi; \
        printf 'tine2k:x:501:20:OpenCode:/home/tine2k:/bin/sh\n' >> /etc/passwd; \
    fi; \
    mkdir -p /home/tine2k; \
    chown 501:20 /home/tine2k

USER 501:20
ENV PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium-browser

# Auto-approve tool permissions that are not explicitly denied.
CMD ["--auto"]
