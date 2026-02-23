# 🚀 initrc: The RC Files Recreator

![Version](https://img.shields.io/badge/version-1.8.0-blue)
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

### 🐳 3. Modern Docker & Git Workflow (de / dl / gstat)
コンテナ選択からログ確認、Git の詳細統計まで。対話型インターフェースで「打ち間違い」をゼロに。

---

## 🛠️ "Recreator" としての核心機能 (v1.8.0 Update)

### 🐳 Next-Gen Docker Workflow
`de` (Exec), `dl` (Logs), `dce` (Compose Exec) コマンドが `fzf` と連携。
コンテナ名やサービス名を覚えなくても、一覧から選択して即座にダイブ。ステータス表示 (`dps`) も色付きで視認性を極限まで高めました。

### 📊 Git-Extras Integration
`git-extras` を標準装備。`gstat` でプロジェクトのサマリーを確認したり、`git ignore` で即座に除外設定を追加したり。標準 Git では届かない痒い所に手が届く設計です。

### 🦾 Reliable Loading Sequence
`Powerlevel10k` -> `.p10k.zsh` -> `common/loader.sh` という緻密な読み込み順序により、プロンプトの高速描画と自作エイリアスの完全な上書きを両立。

### 🤖 AI-Driven Commit (gcm)
`gcm` コマンドが Git の差分を解析し、**AI が最適なコミットメッセージを自動生成**。意味のある履歴を、考える時間をゼロにして構築します。

---

## 🏎️ Power Features

| Command | Feature | Description |
| :--- | :--- | :--- |
| `gcm` | **AI Commit** | AIによるコミットメッセージ自動生成。差分から文脈を読み取ります。 |
| `de` / `dl` | **Docker Fzf** | **(New)** 実行中コンテナを `fzf` で選んで Exec または Logs 表示。 |
| `gstat` | **Git Summary** | **(New)** プロジェクトの統計、作成日、貢献者リストを瞬時に表示。 |
| `copyfile` | **Clipboard** | **(New)** ファイルの中身を一瞬でクリップボードへ。xclip自動連携。 |
| `n` | **Smart Nano** | プレビュー検索から即座に編集開始。TokyoNight背景同期。 |
| `reload` | **Quick Refresh** | 設定を再読み込み。p10k の競合を回避しつつ最新の状態へ。 |

---

## 📂 リポジトリ構造

- **`install.sh`**: OS自動判別・依存ツール（Docker, Git-extras, xclip 等）の一括セットアップ
- **`common/`**: 機能別に分割された設定群
    - `_docker.sh`: **(New)** fzf 連携コンテナ管理 & カラーエイリアス
    - `_system.sh`: 配色・基本コマンド・モダンツール置換
    - `_git.sh`: **gcm (AI Commit)** & Git-extras 連携
    - `loader.sh`: **(Core)** 全ての設定を統合するインテリジェント・ローダー
- **`zsh/` / `bash/`**: 各シェル固有の最適化設定。p10k の読み込み順序を完全制御。

---

## 🚀 クイックスタート

```bash
git clone [https://github.com/rafale2k/initrc.git](https://github.com/rafale2k/initrc.git) ~/dotfiles
cd ~/dotfiles && ./install.sh
source ~/.zshrc  # または reload
```

## 🔑 API Key Setup (for gcm)
gcm (AI Commit) を使用するには Gemini API キーが必要です。

ひな形をコピー: cp ~/dotfiles/common/.env ~/dotfiles/common/.env.local

.env.local を開き、自身のキーを貼り付け
---
© 2026 Rafale / initrc Project.
