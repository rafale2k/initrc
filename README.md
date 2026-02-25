# 🚀 initrc: The RC Files Recreator

![Version](https://img.shields.io/badge/version-1.12.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![OS Support](https://img.shields.io/badge/os-macOS%20%7C%20Ubuntu%20%7C%20RHEL-orange)
![CI Status](https://github.com/rafale2k/initrc/actions/workflows/test.yml/badge.svg)

> **"Environment construction in 0 seconds, with AI at your side."**
> `initrc` は、単なる設定のコピーではありません。実行環境（Mac / SSH / Docker）に合わせてツールを自動調達し、AI 連携とユニバーサル・クリップボードを統合する、エンジニアのための最強スターターキットです。

---

## 🖼️ Showcase

### 🤖 1. AI-Driven Workflow (gcm / ask / wtf)
Gemini 2.0 Flash をエンジンに採用。コミットメッセージ生成、コマンド提案、エラー解析をターミナルから直接実行。


### 📋 2. Universal Clipboard (OSC 52)
Docker コンテナやリモートサーバーから、ホスト側のクリップボードへ。ネットワークの壁を超えたシームレスなコピーを実現。

### 🔍 3. Interactive Operations (fzf + bat)
ファイル検索、Docker コンテナ選択、Git ログ閲覧。すべてがプレビュー付きのインタラクティブな体験に。


---

## 🛠️ "The Oracle Edition" - 核心機能 (v1.12.0 Update)

### 🧠 Unified AI Ecosystem (llm Integration)
AI 実行エンジンを `llm` (Simon Willison) に統一。
- **`gcm`**: Git の差分（`--stat` 含む）を解析し、最適なコミットメッセージを提案。
- **`ask`**: 「100MB以上のファイルを探して」といった自然言語を、実行可能なシェルコマンドへ変換。
- **`wtf`**: 直前のエラーログを解析し、具体的な解決策を提示。

### 🍎 Universal macOS & Linux Support
Apple Silicon (M1/M2/M3) macOS に正式対応。GitHub Actions による macOS 環境での CI テストを導入し、常に安定したセットアップを提供します。

### 📊 Git-extras Integration
`gsum` (summary) でプロジェクトの統計を確認し、`gtoday` (standup) で直近の作業を振り返る。Git を「履歴管理」から「開発分析」のツールへ進化させました。

### 🌐 Universal Clipboard (clipcopy)
`pbcopy` や `xclip` が存在しない Docker 内や SSH 先でも、OSC 52 シーケンスを利用してローカル PC のクリップボードへデータを転送します。

---

## 🏎️ Power Features

| Command | Feature | Description |
| :--- | :--- | :--- |
| `gcm` | **AI Commit** | **(v1.12.0)** 差分解析によるコミットメッセージ生成 & 自動コピー。 |
| `ask` | **AI Oracle** | **(v1.12.0)** 自然言語によるコマンド生成。そのまま実行可能。 |
| `wtf` | **AI Fixer** | **(v1.12.0)** 直前のエラーを解析し、修正案を提示。 |
| `copyfile`| **Uni-Copy** | ファイルの中身を OSC 52 経由でクリップボードへ。 |
| `de` / `dl` | **Docker Fzf** | コンテナを `fzf` で選んで Exec または Logs 表示。 |
| `gsum` | **Git Stats** | プロジェクトの統計、作成日、貢献者リストを表示。 |
| `z` | **Fast Jump** | `zoxide` による学習型ディレクトリ高速移動。 |

---

## 📂 リポジトリ構造

- **`install.sh`**: **(Universal)** OS自動判別、`pipx` / `llm` を含むツール群の一括セットアップ。
- **`bin/`**: AI ツール群の実行ファイル。`llm` をエンジンとしたラッパースクリプト。
- **`common/`**:
    - `_ai_assist.sh`: `ask`, `wtf` のコアロジック。
    - `_system.sh`: OSC 52 連携クリップボード関数 `clipcopy` 搭載。
    - `_docker.sh`: fzf 連携コンテナ管理。
    - `_git.sh`: Git-extras 連携エイリアス。
- **`zsh/`**: `p10k` および `zsh-autosuggestions` 等のプラグイン管理。

---

## 🚀 クイックスタート

```bash
git clone --recursive [https://github.com/rafale2k/initrc.git](https://github.com/rafale2k/initrc.git) ~/dotfiles
cd ~/dotfiles && ./install.sh
```

---

## 🔑 API Key Setup (for AI features)
gcm, ask, wtf を使用するには Gemini API キーが必要です。

~/.dotfiles_env に export GEMINI_API_KEY="your_key" を追記。

エンジンにキーを登録: llm keys set gemini (プロンプトに従い入力)

---
© 2026 Rafale / initrc Project.
