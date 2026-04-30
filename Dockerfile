# 1. ビルドステージ
FROM alpine:3.20 AS builder

# パッケージキャッシュを利用してインストール
RUN apk add --no-cache git python3 py3-pip

# 仮想環境を作成し、LLMツールをインストール
COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install -r requirements.txt && \
    # Pythonのキャッシュ、テスト、不要なコンパイル済みファイルを削除
    find /opt/venv -type d -name "__pycache__" -exec rm -rf {} + && \
    find /opt/venv -type d -name "tests" -exec rm -rf {} + && \
    find /opt/venv -name "*.pyc" -delete

WORKDIR /build
COPY .git .git
COPY .gitmodules .gitmodules
RUN git submodule update --init --recursive
COPY . .

# 徹底的な不要ファイルの削除 (サブモジュールのドキュメントやGit履歴)
RUN find . -name ".git" -exec rm -rf {} + && \
    find . -name "docs" -type d -exec rm -rf {} + && \
    find . -name "examples" -type d -exec rm -rf {} + && \
    # oh-my-zshの未使用プラグインとテーマを削除 (サイズ削減の要)
    cd oh-my-zsh && \
    find plugins -mindepth 1 -maxdepth 1 -type d | grep -vE "^plugins/(git|z)$" | xargs rm -rf && \
    find themes -mindepth 1 -maxdepth 1 -type d | grep -vE "^themes/robbyrussell.zsh-theme$" | xargs rm -rf

# 2. 実行ステージ
FROM alpine:3.20

RUN apk add --no-cache sudo bash zsh git curl python3 tree openssh fzf zoxide coreutils && \
    adduser -D -G wheel -s /bin/zsh rafale && \
    echo "rafale ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY --from=builder /opt/venv /opt/venv
COPY --from=builder --chown=rafale:rafale /build /home/rafale/dotfiles

WORKDIR /home/rafale

RUN ln -sfn /home/rafale/dotfiles/zsh/.zshrc /home/rafale/.zshrc && \
    ln -sfn /home/rafale/dotfiles/zsh/.p10k.zsh /home/rafale/.p10k.zsh && \
    ln -sfn /home/rafale/dotfiles/oh-my-zsh /home/rafale/.oh-my-zsh && \
    ln -sfn /home/rafale/dotfiles/configs/gitconfig /home/rafale/.gitconfig && \
    mkdir -p /home/rafale/.oh-my-zsh/custom/plugins /home/rafale/.oh-my-zsh/custom/themes && \
    ln -sfn /home/rafale/dotfiles/zsh/plugins/zsh-autosuggestions /home/rafale/.oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    ln -sfn /home/rafale/dotfiles/zsh/plugins/zsh-syntax-highlighting /home/rafale/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
    ln -sfn /home/rafale/dotfiles/zsh/plugins/history-search-multi-word /home/rafale/.oh-my-zsh/custom/plugins/history-search-multi-word && \
    ln -sfn /home/rafale/dotfiles/zsh/themes/powerlevel10k /home/rafale/.oh-my-zsh/custom/themes/powerlevel10k && \
    # 所有権設定: GNU chown -h が使えればシンボリックリンク自体に設定する。
    # 失敗した場合はリンク先（またはリンク）に対して通常の chown を試みる。
    (chown -h rafale:rafale /home/rafale/.zshrc /home/rafale/.p10k.zsh /home/rafale/.oh-my-zsh /home/rafale/.gitconfig) || \
    (chown rafale:rafale /home/rafale/.zshrc /home/rafale/.p10k.zsh /home/rafale/.oh-my-zsh /home/rafale/.gitconfig || true)

USER rafale
ENV PATH="/opt/venv/bin:/home/rafale/dotfiles/bin:/home/rafale/dotfiles/scripts:${PATH}"
ENV TERM=xterm-256color
