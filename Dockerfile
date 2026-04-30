# 1. ビルドステージ
FROM alpine:3.20 AS builder

# パッケージキャッシュを利用してインストール
RUN --mount=type=cache,target=/var/cache/apk \
    apk add git python3 py3-pip

# 仮想環境を作成し、LLMツールをインストール
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install llm llm-gemini

WORKDIR /build
# ソースの変更とサブモジュールの更新を分離してキャッシュ効率を最大化
COPY .git .git
COPY .gitmodules .gitmodules
RUN git submodule update --init --recursive
COPY . .
RUN find . -name ".git" -exec rm -rf {} +

# 2. 実行ステージ
FROM alpine:3.20

# 最小限のランタイムパッケージをインストールし、ユーザー作成と設定を一括実行
RUN --mount=type=cache,target=/var/cache/apk \
    apk add sudo bash zsh git curl python3 tree openssh docker-cli fzf zoxide && \
    adduser -D -s /bin/zsh rafale && \
    addgroup rafale wheel && \
    echo "rafale ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ビルド済み資産のコピー
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder --chown=rafale:rafale /build /home/rafale/dotfiles

WORKDIR /home/rafale

# 設定ファイルとプラグインのシンボリックリンクを一括作成
RUN ln -sfn /home/rafale/dotfiles/zsh/.zshrc /home/rafale/.zshrc && \
    ln -sfn /home/rafale/dotfiles/zsh/.p10k.zsh /home/rafale/.p10k.zsh && \
    ln -sfn /home/rafale/dotfiles/oh-my-zsh /home/rafale/.oh-my-zsh && \
    ln -sfn /home/rafale/dotfiles/configs/gitconfig /home/rafale/.gitconfig && \
    mkdir -p /home/rafale/.oh-my-zsh/custom/plugins /home/rafale/.oh-my-zsh/custom/themes && \
    ln -sfn /home/rafale/dotfiles/zsh/plugins/zsh-autosuggestions /home/rafale/.oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    ln -sfn /home/rafale/dotfiles/zsh/plugins/zsh-syntax-highlighting /home/rafale/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
    ln -sfn /home/rafale/dotfiles/zsh/plugins/history-search-multi-word /home/rafale/.oh-my-zsh/custom/plugins/history-search-multi-word && \
    ln -sfn /home/rafale/dotfiles/zsh/themes/powerlevel10k /home/rafale/.oh-my-zsh/custom/themes/powerlevel10k && \
    chown -h rafale:rafale /home/rafale/.zshrc /home/rafale/.p10k.zsh /home/rafale/.oh-my-zsh /home/rafale/.gitconfig

USER rafale
ENV PATH="/opt/venv/bin:/home/rafale/dotfiles/bin:/home/rafale/dotfiles/scripts:${PATH}"
ENV TERM=xterm-256color
