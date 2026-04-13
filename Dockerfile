FROM alpine:latest AS builder

RUN apk add --no-cache git python3 py3-pip
RUN pip install --no-cache-dir llm llm-gemini --break-system-packages

WORKDIR /build
COPY . .

RUN git submodule update --init --recursive && find . -name ".git" -exec rm -rf {} +

FROM alpine:latest

# 必要なパッケージのインストール
RUN apk add --no-cache sudo bash zsh git curl python3 tree openssh docker-cli fzf zoxide

# ユーザーの作成を先に実行
RUN adduser -D -s /bin/zsh rafale && \
    addgroup rafale wheel && \
    echo "rafale ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# builderステージからファイルをコピー
# Pythonのsite-packagesをワイルドカードでコピーし、OSのバージョン変化に追従しやすくする
COPY --from=builder /usr/lib/python3* /usr/lib/
COPY --from=builder /usr/bin/llm* /usr/bin/
COPY --from=builder --chown=rafale:rafale /build /home/rafale/dotfiles

WORKDIR /home/rafale

# シンボリックリンクの作成（可読性向上のため分割）
RUN ln -sfn /home/rafale/dotfiles/zsh/.zshrc /home/rafale/.zshrc && \
    ln -sfn /home/rafale/dotfiles/zsh/.p10k.zsh /home/rafale/.p10k.zsh && \
    ln -sfn /home/rafale/dotfiles/oh-my-zsh /home/rafale/.oh-my-zsh && \
    ln -sfn /home/rafale/dotfiles/configs/gitconfig /home/rafale/.gitconfig

RUN mkdir -p /home/rafale/.oh-my-zsh/custom/plugins /home/rafale/.oh-my-zsh/custom/themes && \
    ln -sfn /home/rafale/dotfiles/zsh/plugins/zsh-autosuggestions /home/rafale/.oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    ln -sfn /home/rafale/dotfiles/zsh/plugins/zsh-syntax-highlighting /home/rafale/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
    ln -sfn /home/rafale/dotfiles/zsh/plugins/history-search-multi-word /home/rafale/.oh-my-zsh/custom/plugins/history-search-multi-word && \
    ln -sfn /home/rafale/dotfiles/zsh/themes/powerlevel10k /home/rafale/.oh-my-zsh/custom/themes/powerlevel10k

# 権限の整理
RUN chown -h rafale:rafale /home/rafale/.zshrc /home/rafale/.p10k.zsh /home/rafale/.oh-my-zsh /home/rafale/.gitconfig && \
    chown -R rafale:rafale /home/rafale/dotfiles /home/rafale/.oh-my-zsh

USER rafale
ENV PATH="/home/rafale/dotfiles/bin:/home/rafale/dotfiles/scripts:${PATH}"
ENV TERM=xterm-256color
