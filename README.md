# 🚀 Always same Server Environment (initrc)

サーバーログイン後の「環境構築」を0秒にするための、ドットファイル・リポジトリです。
Bash, Zsh, Vim, Nano, Docker の設定を統合し、必要なツールを全自動でセットアップします。

## ✨ 主な機能

- **Auto Tool Installer**: `git`, `tree`, `fzf`, `ccze`, `bat` 等の必須ツールを自動チェック＆インストール。
- **Cross-Shell Aliases**: Bash/Zsh 両対応の爆速エイリアス（Git, Docker, ナビゲーション）。
- **Docker Optimization**: API v1.53 対応。コンテナ管理・ログ監視・クリーンアップを簡略化。
- **Editor Sync**: Vim (NERDTree/Lightline/Molokai) と Nano (Syntax Highlight/Mouse) を即時展開。
- **Terminal Design**: Tokyo Night 配色（Rlogin対応）と Powerlevel10k によるモダンな UI。

## 🛠 クイックスタート

新しいサーバーにログインしたら、以下のコマンドを叩くだけです。

```bash
git clone [https://github.com/rafale2k/initrc.git](https://github.com/rafale2k/initrc.git) ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
