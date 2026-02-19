# 🚀 initrc - The Ultimate Server Initialization Kit

[![Git](https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white)](https://git-scm.com/)
[![Zsh](https://img.shields.io/badge/Zsh-000000?style=for-the-badge&logo=zsh&logoColor=white)](https://www.zsh.org/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)

サーバーログイン後の「環境構築」を0秒にする。
Bash, Zsh, Vim, Nano, Docker の設定を統合し、あらゆるLinux環境を即座に自分専用のコクピットに変えるドットファイル・リポジトリです。

---

## ✨ 主な機能

### 🛠️ Smart Installer
- **Dependency Check**: `git`, `tree`, `fzf`, `ccze`, `bat` 等のツールを自動検知し、不足があればその場でインストール。
- **Auto-Path Resolution**: インストール先を動的に判別。`root` ユーザーの `nano` や `vim` でもパスエラーなしでシンタックスハイライトが効きます。

### 🏎️ Power Aliases (Cross-Shell)
Bash と Zsh の両方で動作する一貫した操作感。
- `gcm`: **Interactive Commit**. `fzf` を使った Conventional Commits 形式の対話型コミット。
- `dl`: **Docker Log Selector**. 起動中のコンテナを `fzf` で選んで `ccze` (色付き) でログを監視。
- `si` / `ss`: **Safe Root Mode**. root 昇格時に背景色を警告色（赤）に変更し、事故を防止。

### 🎨 Design & UX
- **Theme**: Tokyo Night (Storm) 配色。
- **Shell**: Powerlevel10k による直感的なプロンプト（Gitステータス、Dockerアイコン表示）。
- **Editor**: 
  - **Vim**: NERDTree / Lightline / Molokai 構成。
  - **Nano**: Monokai Syntax Highlighting 完備。

---

## 🚀 クイックスタート

新しいサーバーにログインし、以下のコマンドを実行するだけ。

```bash
git clone [https://github.com/rafale2k/initrc.git](https://github.com/rafale2k/initrc.git) ~/dotfiles
cd ~/dotfiles && ./install.sh
実行後、exec zsh -l または reload で環境が反映されます。

📂 ディレクトリ構成
common/: Bash/Zsh 共通のエイリアスと関数（gcm, dl など）

editors/: Vim / Nano のテーマと設定ファイル

zsh/ & bash/: 各シェルの固有設定

install.sh: 全自動セットアップスクリプト

Developed with ❤️ for efficient server management.
