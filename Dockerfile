# --- Stage 1: Dependency Builder (重たいビルド担当) ---
FROM alpine:latest AS builder

RUN apk add --no-cache python3 py3-pip
# --break-system-packages を使いつつ、キャッシュを効かせる
RUN pip install --no-cache-dir llm llm-gemini --break-system-packages

# --- Stage 2: Final Runtime (軽量・高速起動担当) ---
FROM alpine:latest

# 1. 変更頻度の低いシステムツールを先に固める（キャッシュ用）
RUN apk add --no-cache \
    sudo bash zsh git curl python3 tree openssh \
    docker-cli fzf zoxide

# 2. builder ステージからインストール済みの Python パッケージだけを奪い取る
# これでビルドのたびに pip install が走るのを防ぐ
COPY --from=builder /usr/lib/python3*/site-packages /usr/lib/python3.12/site-packages
COPY --from=builder /usr/bin/llm* /usr/bin/

# 3. ユーザー設定
RUN adduser -D -s /bin/zsh rafale && \
    addgroup rafale wheel && \
    echo "rafale ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /home/rafale

# 4. ここからが「速さ」のキモ：変更の多いファイルを分ける
# .dockerignore で .git などを除外している前提
COPY --chown=rafale:rafale . /home/rafale/dotfiles

# 1. 必要なリンクを網羅して強制的に貼る (ln -sfn)
RUN ln -sfn /home/rafale/dotfiles/zsh/.zshrc /home/rafale/.zshrc && \
    ln -sfn /home/rafale/dotfiles/configs/.p10k.zsh /home/rafale/.p10k.zsh && \
    ln -sfn /home/rafale/dotfiles/oh-my-zsh /home/rafale/.oh-my-zsh && \
    ln -sfn /home/rafale/dotfiles/configs/gitconfig /home/rafale/.gitconfig

# 2. リンクの所有権を rafale に渡す
RUN chown -h rafale:rafale /home/rafale/.zshrc \
                           /home/rafale/.p10k.zsh \
                           /home/rafale/.oh-my-zsh \
                           /home/rafale/.gitconfig

# 3. 最後に念押しでユーザーとディレクトリを指定
USER rafale
WORKDIR /home/rafale

# 5. 環境変数
ENV PATH="/home/rafale/dotfiles/bin:/home/rafale/dotfiles/scripts:${PATH}"
ENV TERM=xterm-256color

# 6. install.sh の実行（スクリプトが不変ならここもキャッシュされる）
RUN cd /home/rafale/dotfiles && \
    chmod +x install.sh && \
    ./install.sh || echo "Installation skips handled"

USER rafale
ENTRYPOINT ["/bin/zsh", "-l"]
