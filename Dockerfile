FROM alpine:latest

# 必要なツールを全部盛り（llm用のpython3-pipも含む）
RUN apk add --no-cache \
    bash zsh git curl python3 py3-pip tree openssh \
    docker-cli fzf zoxide

# llm コマンドのインストール
RUN pip install llm --break-system-packages

RUN adduser -D -s /bin/zsh rafale
RUN addgroup rafale wheel
USER rafale
WORKDIR /home/rafale

# 手元で git submodule update --init --recursive 済みである前提
COPY --chown=rafale:rafale . /home/rafale/dotfiles
COPY --chown=rafale:rafale ./ /home/rafale/dotfiles/

RUN ls -la /home/rafale/dotfiles

# install.sh を「Dockerモード」で動かす工夫
RUN cd /home/rafale/dotfiles && \
    sed -i 's/\r$//' install.sh && \
    chmod +x install.sh && \
    # サブモジュール同期で落ちないように、一時的にダミーの .git を作るか
    # あるいは install.sh 側でエラーを無視するように仕向ける
    ./install.sh || echo "Installation finished with some skips"

# リンク作成とパス通し、そして install.sh の実行
RUN cd /home/rafale/dotfiles && \
    ln -sf /home/rafale/dotfiles/zsh/.zshrc /home/rafale/.zshrc && \
    ln -sf /home/rafale/dotfiles/zsh/.p10k.zsh /home/rafale/.p10k.zsh && \
    ln -sfn /home/rafale/dotfiles/oh-my-zsh /home/rafale/.oh-my-zsh && \
    sed -i 's/\r$//' install.sh && \
    chmod +x install.sh && \
    ./install.sh || echo "Installation finished"

# パスを永続的に通す
ENV PATH="/home/rafale/dotfiles/bin:/home/rafale/dotfiles/scripts:$PATH"

# 起動時に API キーを渡せるようにする準備（任意）
# ENV GEMINI_API_KEY="" 

ENTRYPOINT ["/bin/zsh", "-l"]
