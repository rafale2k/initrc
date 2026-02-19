# 🚀 initrc: The RC Files Recreator

[![Git](https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white)](https://git-scm.com/)
[![Zsh](https://img.shields.io/badge/Zsh-000000?style=for-the-badge&logo=zsh&logoColor=white)](https://www.zsh.org/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)

**"Environment construction in 0 seconds."** `initrc` は、単なる設定のコピーではなく、実行環境に合わせて設定ファイルを動的に **"Recreate（再生成）"** する、Linuxサーバー管理者のための最強スターターキットです。

---

## 🛠️ "Recreator" としての核心機能

### 1. Dynamic Path Resolution (Smart Nano/Vim)
インストール時の絶対パスを自動検知。`root` ユーザーでもパスエラーを吐かさない、動的な `.nanorc` 生成ロジックを搭載。どこに clone しても、その場で最適な設定を再構築します。

### 2. Zero-Conflict Shell Integration
- **Cross-Shell Aliases**: Bash/Zsh 両対応。
- **Auto-Unalias**: 関数の競合（`de`, `dl` など）を自動で回避。既存のエイリアスに邪魔されず、常に最新のツールセットを展開します。

### 3. All-in-One Tool Auto-Installer
`fzf`, `tree`, `bat`, `ccze`, `git` ... 必須ツールがなければその場でインストール。依存関係に悩む時間をゼロにします。

---

## 🏎️ Power Features

- **gcm**: `fzf` による対話型コミット。コミットメッセージを考える時間を短縮。
- **dl / de**: Docker ログ監視・コンテナ侵入を `fzf` で直感的に。
- **Safe Root**: `si` / `ss` による root 昇格時の背景色警告（事故防止機能）。
- **Modern UI**: Tokyo Night 配色 ＋ Powerlevel10k による情報の可視化。

---

## 🚀 クイックスタート

```bash
git clone [https://github.com/rafale2k/initrc.git](https://github.com/rafale2k/initrc.git) ~/dotfiles
cd ~/dotfiles && ./install.sh
実行後、exec zsh -l で "Recreated" された環境が適用されます。

## 📂 リポジトリ構造
common/: シェル共通のエイリアス & 高度な関数群

editors/: 環境適応型の Vim / Nano プロファイル

install.sh: Core Recreator Script（パス置換・ツール展開・リンク作成）

Developed with ❤️ by rafale2k.

"Stop configuring, start creating."
