# --- Stage 1: Dependency Builder ---
FROM alpine:latest AS builder
RUN apk add --no-cache python3 py3-pip
RUN pip install --no-cache-dir llm llm-gemini --break-system-packages

# --- Stage 2: Final Runtime ---
FROM alpine:latest

# 1. システムツールのインストール
RUN apk add --no-cache \
    sudo bash zsh git curl python3 tree openssh \
    docker-cli fzf zoxide

# 2. builder ステージから Python パッケージを奪い取る
# ※ Alpineのバージョンによってパスが変わる可能性があるのでワイルドカードを活用
COPY --from=builder /usr/lib/python3*/site-packages /usr/lib/python3.12/site-packages
COPY --from=builder /usr/bin/llm* /usr/bin/

# 3. ユーザー設定
RUN adduser -D -s /bin/zsh rafale && \
    addgroup rafale wheel && \
    echo "rafale ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /home/rafale

# 4. dotfiles のコピーと権限設定
# .dockerignore で .git を除外していないことが前提（サブモジュール取得に必要）
COPY --chown=rafale:rafale . /home/rafale/dotfiles
RUN git config --global --add safe.directory /home/rafale/dotfiles

# 5. 【重要】サブモジュールの展開と自動リンク
# ビルド時に実体を取得し、Oh My Zshが認識できる場所にガッチリ固定する
RUN cd /home/rafale/dotfiles && \
    (git submodule update --init --recursive || true) && \
    # 基本のリンク作成
    ln -sfn /home/rafale/dotfiles/zsh/.zshrc /home/rafale/.zshrc && \
    ln -sfn /home/rafale/dotfiles/configs/.p10k.zsh /home/rafale/.p10k.zsh && \
    ln -sfn /home/rafale/dotfiles/oh-my-zsh /home/rafale/.oh-my-zsh && \
    ln -sfn /home/rafale/dotfiles/configs/gitconfig /home/rafale/.gitconfig && \
    # --- Oh My Zsh カスタムリンクの作成 ---
    mkdir -p /home/rafale/.oh-my-zsh/custom/plugins /home/rafale/.oh-my-zsh/custom/themes && \
    ln -sfn /home/rafale/dotfiles/zsh/plugins/zsh-autosuggestions /home/rafale/.oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    ln -sfn /home/rafale/dotfiles/zsh/plugins/zsh-syntax-highlighting /home/rafale/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
    ln -sfn /home/rafale/dotfiles/zsh/plugins/history-search-multi-word /home/rafale/.oh-my-zsh/custom/plugins/history-search-multi-word && \
    ln -sfn /home/rafale/dotfiles/zsh/themes/powerlevel10k /home/rafale/.oh-my-zsh/custom/themes/powerlevel10k && \
    # 所有権の整理（シンボリックリンク自体とその中身）
    chown -R rafale:rafale /home/rafale/

# 6. 最終設定
USER rafale
WORKDIR /home/rafale
ENV PATH="/home/rafale/dotfiles/bin:/home/rafale/dotfiles/scripts:${PATH}"
ENV TERM=xterm-256color

# 念押しで .zshrc があるかチェック
RUN [ -f /home/rafale/.zshrc ] || echo "⚠️ Warning: .zshrc not found!"
