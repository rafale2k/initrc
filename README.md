# 🚀 initrc: The RC Files Recreator

![Version](https://img.shields.io/badge/version-1.7.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![OS Support](https://img.shields.io/badge/os-Ubuntu%20%7C%20RHEL%20%7C%20macOS-orange)

> **"Environment construction in 0 seconds, across any shell."**
> `initrc` は、単なる設定のコピーではありません。実行環境に合わせてツールを自動調達し、設定ファイルを動的に **"Recreate（再生成）"** する、エンジニアのための最強スターターキットです。

---

## 🖼️ Showcase

### 🔍 1. Interactive File Search (n / fe)
`fzf` + `bat` による高速プレビュー検索。エディタを開く前に中身を瞬時に確認。
![Smart Search](assets/51.jpg)

### 🌳 2. Smart Navigation (zi)
`zoxide` と `eza` が連携。ツリー表示でプレビューしながら爆速移動。
![Navigation Preview](assets/52.jpg)

### 🎨 3. Terminal UI & Color Context
**Tokyo Night** の洗練された配色。Rloginなどのパレット依存ターミナルでも、エスケープシーケンスにより背景色を強制同期。
![Total UI Experience](assets/53.jpg)

---

## 🛠️ "Recreator" としての核心機能 (v1.7.0 Update)

### 🤖 AI-Driven Commit (gcm)
`gcm` コマンドが Git の差分を解析し、**AI が最適なコミットメッセージを自動生成**。意味のある履歴を、考える時間をゼロにして構築します。

### 📦 Hybrid Shell Loader v2
ZshとBashの両環境で `DOTFILES_PATH` を物理的に解決。Ubuntu/macOSから、RHEL/AlmaLinuxのroot環境まで、一貫したエイリアスと関数を提供します。

### 🎨 Tokyo Night Persistence
パレット設定が不安定なリモート環境でも、`hooks.zsh` が ANSI エスケープシーケンスを用いて **Tokyo Night** のパレット(16色)と背景色を強制維持。

---

## 🏎️ Power Features

| Command | Feature | Description |
| :--- | :--- | :--- |
| `gcm` | **AI Commit** | **(New)** AIによるコミットメッセージ自動生成。差分から文脈を読み取ります。 |
| `n` | **Smart Nano** | **(Core)** プレビュー検索から即座に編集開始。TokyoNight背景同期。 |
| `fe` | **File Explorer** | `fd` + `bat` による高速プレビュー検索。エディタで開く。 |
| `zi` | **Smart Jump** | `zoxide` 連携。`eza` によるツリープレビュー付きワープ。 |
| `reload` | **Quick Refresh** | `~/.zshrc` を再読み込みし、最新の設定を即座に反映。 |

---

## 📂 リポジトリ構造

- **`install.sh`**: OS自動判別・依存ツール一括セットアップ
- **`common/`**: 機能別に分割された設定群
    - `_system.sh`: 配色・基本コマンド・モダンツール置換
    - `_git.sh`: **gcm (AI Commit)** 等のGitワークフロー強化
    - `_navigation.sh`: `n`, `fe`, `zi` 等の対話型ナビゲーション
    - `loader.sh`: **(Core)** Zsh/Bash 両対応のインテリジェント・ローダー
- **`zsh/` / `bash/`**: 各シェル固有の最適化設定

## 🚀 クイックスタート

```bash
git clone [https://github.com/rafale2k/initrc.git](https://github.com/rafale2k/initrc.git) ~/dotfiles
cd ~/dotfiles && ./install.sh
source ~/.zshrc  # または reload
```
---
© 2026 Rafale / initrc Project.
---
