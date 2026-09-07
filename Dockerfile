# syntax=docker/dockerfile:1

# ==========================================
# 1. fzf ビルドステージ (Go製バイナリのビルド)
# ==========================================
FROM golang:1.27.1-alpine@sha256:cf6fca6641884b8433441b2b0652976f975e1d0fdd26d177eaaf8596087f3125 AS fzf-builder

ARG FZF_VERSION=v0.74.3

# Go モジュールとビルドキャッシュをマウントして高速化・静的リンクでビルド
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 go install -ldflags="-s -w" github.com/junegunn/fzf@${FZF_VERSION}

# ==========================================
# 2. Python 仮想環境ビルドステージ
# ==========================================
FROM alpine:3.24@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b AS python-builder

RUN --mount=type=cache,target=/var/cache/apk \
    apk update && apk upgrade --no-cache && \
    apk add --no-cache python3 py3-pip

COPY requirements.txt /tmp/requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install -r /tmp/requirements.txt && \
    /opt/venv/bin/pip uninstall -y setuptools && \
    # 不要なバイトコードおよびセキュリティスキャナで誤検知される静的SBOMファイルを削除
    find /opt/venv -type d -name "__pycache__" -exec rm -rf {} + && \
    find /opt/venv -name "*.pyc" -delete && \
    find /opt/venv -name "*.cdx.json" -delete && \
    find /opt/venv -type d -name "sboms" -exec rm -rf {} +

# ==========================================
# 3. dotfiles 整理ステージ (軽量Alpineで不要ファイル削除)
# ==========================================
FROM alpine:3.24@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b AS dotfiles-builder

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN --mount=type=cache,target=/var/cache/apk \
    apk update && apk upgrade --no-cache && \
    apk add --no-cache git

WORKDIR /build
COPY . .

# サブモジュールが未チェックアウトの場合のみ git submodule update を実行
RUN if [ ! -f "oh-my-zsh/oh-my-zsh.sh" ] && [ -d ".git" ]; then \
        git submodule update --init --recursive; \
    fi && \
    # 徹底的な不要ファイル削除 (Git履歴、ドキュメント、CI/エディタ設定など)
    find . -name ".git" -exec rm -rf {} + && \
    find . -name "docs" -type d -exec rm -rf {} + && \
    find . -name "examples" -type d -exec rm -rf {} + && \
    find . -name ".vscode" -type d -exec rm -rf {} + && \
    find . -name ".github" -type d -exec rm -rf {} + && \
    find . -mindepth 2 -name "Dockerfile" -delete && \
    find . -name "*.md" -not -name "README.md" -delete && \
    find . -name "LICENSE*" -delete && \
    find . -name "CHANGELOG*" -delete && \
    # oh-my-zshの未使用プラグインとテーマを削除 (サイズ削減の要)
    find oh-my-zsh/plugins -mindepth 1 -maxdepth 1 \
        ! -name "git" \
        ! -name "git-extras" \
        ! -name "docker" \
        ! -name "docker-compose" \
        ! -name "copyfile" \
        ! -name "copypath" \
        ! -name "z" \
        -exec rm -rf {} + && \
    find oh-my-zsh/themes -mindepth 1 -maxdepth 1 \
        ! -name "robbyrussell.zsh-theme" \
        -exec rm -rf {} +

# ==========================================
# 4. 実行ステージ
# ==========================================
FROM alpine:3.24@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b AS runtime

# セキュリティ更新の適用と最小限パッケージのインストール
# ※ py3-pip は不要（/opt/venv を流用）、openssh は openssh-client に限定して脆弱性サーフェスを最小化
RUN --mount=type=cache,target=/var/cache/apk \
    apk update && apk upgrade --no-cache && \
    apk add --no-cache \
        sudo \
        bash \
        zsh \
        git \
        curl \
        python3 \
        tree \
        openssh-client \
        openssl \
        zoxide \
        coreutils && \
    adduser -D -u 1000 -G wheel -s /bin/zsh rafale && \
    echo "rafale ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/rafale && \
    chmod 0440 /etc/sudoers.d/rafale

# 各ビルダーからの成果物をコピー
COPY --from=fzf-builder /go/bin/fzf /usr/local/bin/fzf
COPY --from=python-builder /opt/venv /opt/venv
COPY --from=dotfiles-builder --chown=rafale:rafale /build /home/rafale/dotfiles

# ユーザー権限でシンボリックリンクを作成（chown処理不要で高速・安全）
USER rafale
WORKDIR /home/rafale

RUN ln -sfn /home/rafale/dotfiles/zsh/.zshrc /home/rafale/.zshrc && \
    ln -sfn /home/rafale/dotfiles/zsh/.p10k.zsh /home/rafale/.p10k.zsh && \
    ln -sfn /home/rafale/dotfiles/oh-my-zsh /home/rafale/.oh-my-zsh && \
    ln -sfn /home/rafale/dotfiles/configs/gitconfig /home/rafale/.gitconfig && \
    mkdir -p /home/rafale/.oh-my-zsh/custom/plugins /home/rafale/.oh-my-zsh/custom/themes && \
    ln -sfn /home/rafale/dotfiles/zsh/plugins/zsh-autosuggestions /home/rafale/.oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    ln -sfn /home/rafale/dotfiles/zsh/plugins/zsh-syntax-highlighting /home/rafale/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
    ln -sfn /home/rafale/dotfiles/zsh/plugins/history-search-multi-word /home/rafale/.oh-my-zsh/custom/plugins/history-search-multi-word && \
    ln -sfn /home/rafale/dotfiles/zsh/themes/powerlevel10k /home/rafale/.oh-my-zsh/custom/themes/powerlevel10k

ENV PATH="/opt/venv/bin:/home/rafale/dotfiles/bin:/home/rafale/dotfiles/scripts:${PATH}"
ENV TERM=xterm-256color
