# 🚀 initrc: The RC Files Recreator

![Version](https://img.shields.io/badge/version-1.13.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![OS Support](https://img.shields.io/badge/os-macOS%20%7C%20Ubuntu%20%7C%20RHEL-orange)
![CI Status](https://github.com/rafale2k/initrc/actions/workflows/test.yml/badge.svg)
![Linting](https://img.shields.io/badge/shellcheck-100%25%20passing-brightgreen)
[![X](https://img.shields.io/badge/X-@rafale-1DA1F2?style=flat&logo=x&logoColor=white)](https://x.com/rafale)

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

## 🛠️ "The ShellCheck Edition" - 核心機能 (v1.13.0 Update)

### ✅ Production-Ready Reliability
本バージョンより、全てのシェルスクリプトに対して **ShellCheck** による厳密な静的解析を導入。
- **バグの根絶**: 構文エラー、不適切な変数展開、未定義変数の参照を徹底排除。
- **ポータビリティ**: Bash/Zsh 両環境において、一貫した動作を保証するための高度なリファクタリングを実施。

### 🧠 Unified AI Ecosystem (llm Integration)
AI 実行エンジンを `llm` (Simon Willison) に統一。
- **`gcm`**: Git の差分を解析し、最適なコミットメッセージを提案。
- **`ask`**: 自然言語を、即実行可能なシェルコマンドへ変換。
- **`wtf`**: 直前のエラーログを解析し、具体的な解決策を提示。

---

# 🤖 AI-Powered Docker Tools: Professional Usage

## 🐳 dask (Docker Assistant Task)
自然言語で指示を出すだけで、複雑な Docker コマンドを生成・実行します。
`dask "一番メモリを食っているコンテナを特定して"`

## 🔍 dinv (Docker Inspector)
コンテナ内の設定ファイルやログを SRE 視点で精密診断します。
`dinv maria-db /etc/mysql/my.cnf "パフォーマンス設定をチェックして"`

## 🛠️ wtf (Instant Error Analyzer)
ターミナルに表示されたエラーの正体を即座に解析し、解決策を提示します。
`wtf "ERROR: connection refused to host 127.0.0.1"`

---

## 🏎️ Power Features

| Command | Feature | Description |
| :--- | :--- | :--- |
| `gcm` | **AI Commit** | 差分解析によるコミットメッセージ生成 & 自動コピー。 |
| `ask` | **AI Oracle** | 自然言語によるコマンド生成。そのまま実行可能。 |
| `wtf` | **AI Fixer** | 直前のエラーを解析し、修正案を提示。 |
| `copyfile`| **Uni-Copy** | ファイルの中身を OSC 52 経由でクリップボードへ。 |
| `de` / `dl` | **Docker Fzf** | コンテナを `fzf` で選んで Exec または Logs 表示。 |
| `gsum` | **Git Stats** | プロジェクトの統計、作成日、貢献者リストを表示。 |
| `z` | **Fast Jump** | `zoxide` による学習型ディレクトリ高速移動。 |

---

## 📂 リポジトリ構造

- **`install.sh`**: OS自動判別、`pipx` / `llm` を含むツール群の一括セットアップ。
- **`bin/`**: AI ツール群の実行ファイル。`llm` をエンジンとしたラッパースクリプト。
- **`common/`**:
    - `_ai_assist.sh`: `ask`, `wtf` のコアロジック。ShellCheck 準拠。
    - `_system.sh`: Tokyo Night 配色制御 & `clipcopy` 搭載。
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

## 🔑 API Key Setup
- ~/.dotfiles_env に export GEMINI_API_KEY="your_key" を追記。

- エンジンにキーを登録: llm keys set gemini (プロンプトに従い入力

---

© 2026 Rafale / initrc Project.
