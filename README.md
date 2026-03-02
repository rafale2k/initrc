# 🚀 initrc: The RC Files Recreator

![Version](https://img.shields.io/badge/version-1.15.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![OS Support](https://img.shields.io/badge/os-macOS%20%7C%20Ubuntu%20%7C%20AlmaLinux-orange)
![CI Status](https://github.com/rafale2k/initrc/actions/workflows/test.yml/badge.svg)
![Linux CI](https://github.com/rafale2k/initrc/actions/workflows/linux-distros.yml/badge.svg)
![AI](https://img.shields.io/badge/AI-Gemini%202.5%20Flash-vibrantblue?logo=google-gemini&logoColor=white)
![LLM](https://img.shields.io/badge/LLM-llm%20integrated-6f42c1?logo=python&logoColor=white)
![Linting](https://img.shields.io/badge/shellcheck-100%25%20passing-brightgreen)
![IaC](https://img.shields.io/badge/concept-IaC%20Ready-lightgrey?logo=terraform&logoColor=623CE4)
![Installer](https://img.shields.io/badge/installer-idempotent-blueviolet)
[![X](https://img.shields.io/badge/X-@rafale-1DA1F2?style=flat&logo=x&logoColor=white)](https://x.com/rafale)

> **"Environment construction in 0 seconds, with Gemini 2.5 at your side."**
> `initrc` は、単なる設定のコピーではありません。実行環境（Cloud / Docker / Bare-metal）に合わせてツールを自動調達し、最新の AI 連携とシームレスな操作系を統合する、エンジニアのための最強スターターキットです。

---

## 🖼️ Showcase

### 🤖 1. Next-Gen AI Workflow (ginv / gcm / ask / wtf)
**Gemini 2.5 Flash** をエンジンに採用。プロンプト応答、コミットメッセージ生成、エラー解析をターミナルから爆速で実行。`llm` エコシステムに完全統合されています。

### 📋 2. Universal Clipboard & Path Management
OSC 52 によるリモート・ローカル間のクリップボード共有に加え、v1.15.0 ではインストーラーによる **PATH の自動修復機能** を搭載。セットアップ直後から全ての自作スクリプトが即座に利用可能です。

### 🔍 3. Interactive Operations (fzf + bat + eza)
ファイル検索、Docker コンテナ管理。すべてがプレビュー付きのインタラクティブな体験に。AlmaLinux/Ubuntu 両対応のモダンな代替コマンド群（`eza`, `fd`, `bat`）を網羅。

---

## 🛠️ v1.15.0 "The AI-Refined Edition" - 核心機能

### ✅ Professional Reliability & ShellCheck
全てのシェルスクリプトに対して **ShellCheck** による厳密な静的解析を実施。
- **堅牢なインストーラー**: 依存関係の解決順序を最適化し、`ginv` 等のツール配備とパス通しを一挙に完結。
- **クロスプラットフォーム**: Ubuntu (Debian系) と AlmaLinux (RHEL系) の両方で、バイナリレベルでの互換動作を保証。

### 🧠 Unified AI Ecosystem (llm + Gemini 2.5)
AI 実行エンジンを `llm` に統一。2026年最新の **Gemini 2.5 Flash** をデフォルトモデルとしてプリセットします。
- **`ginv`**: AI への汎用的な問いかけ。`ginv "このログの異常値を指摘して"`。
- **`gcm`**: Git 差分から最適なコミットメッセージを提案。
- **`wtf`**: 直前のエラーを解析し、具体的な修正コードを提示。

---

## 🤖 AI-Powered SRE Tools

### 🐳 `dask` (Docker Assistant Task)
自然言語で指示を出すだけで、複雑な Docker コマンドを生成・実行。
> `dask "一番メモリを食っているコンテナを特定して"`

### 🛠️ `wtf` (Instant Error Analyzer)
ターミナルに表示されたエラーを即座に解析。
> `wtf "ERROR: connection refused to host 127.0.0.1"`

---

## 🏎️ Power Features

| Command | Feature | Description |
| :--- | :--- | :--- |
| `ginv` | **AI Oracle** | **[NEW]** Gemini 2.5 による汎用 AI 問いかけツール。 |
| `gcm` | **AI Commit** | 差分解析によるコミットメッセージ生成。 |
| `wtf` | **AI Fixer** | 直前のエラーを解析し、修正案を提示。 |
| `copyfile`| **Uni-Copy** | ファイル内容を OSC 52 経由でクリップボードへ。 |
| `de` / `dl` | **Docker Fzf** | コンテナを `fzf` で選択し Exec または Logs 表示。 |
| `z` | **Fast Jump** | `zoxide` による学習型ディレクトリ高速移動。 |

---

## 📂 リポジトリ構造

- **`install.sh`**: OS自動判別、`pipx` / `llm` / `ginv` を含む一括セットアップ。
- **`bin/`**: AI ツール群の実行ファイル。
- **`common/`**:
  - `install_functions.sh`: セットアップのコアロジック。ShellCheck 準拠。
  - `loader.sh`: 非対話シェルでも設定を共有する共通ローダー。
- **`zsh/`**: `p10k` および `zsh-autosuggestions` 等のプラグイン・テーマ管理。

---

## 🚀 クイックスタート

```bash
git clone --recursive [https://github.com/rafale2k/initrc.git](https://github.com/rafale2k/initrc.git) ~/dotfiles
cd ~/dotfiles && ./install.sh
exec zsh -l
```

---

## 🔑 API Key Setup
- ~/.dotfiles_env に export GEMINI_API_KEY="your_key" を追記。

- エンジンにキーを登録: llm keys set gemini # プロンプトに従い API Key を入力

---

© 2026 Rafale / initrc Project.
