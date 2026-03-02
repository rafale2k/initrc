# 🚀 initrc: The RC Files Recreator

# 🚀 initrc: The RC Files Recreator

![Version](https://img.shields.io/badge/version-1.16.0-red)
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
> `initrc` は、実行環境に合わせてツールを自動調達し、最新の AI 連携とシームレスな操作系を統合する、エンジニアのための最強スターターキットです。

---

## 🖼️ Showcase

![initrc Showcase Banner](assets/54.png)

### 🤖 1. Next-Gen AI Workflow (ginv / gcm / ask / wtf)
**Gemini 2.5 Flash** をエンジンに採用。プロンプト応答、コミットメッセージ生成、エラー解析をターミナルから爆速で実行。`llm` エコシステムに完全統合されています。

### 📁 2. Structured Configuration (v1.16.0 NEW)
設定ファイルを `common/` ディレクトリに集約し、アルファベット順に自動ロードする **Dynamic Loader** を搭載。機能追加がファイルを置くだけで完結します。

### 🔍 3. Interactive Operations (fzf + bat + eza)
ファイル検索、Docker コンテナ管理。すべてがプレビュー付きのインタラクティブな体験に。Nano Wrapper (`n`) は編集時にパレットを自動変更する職人仕様です。

---

## 🛠️ v1.16.0 "The Structural Refactor" - 核心機能

### 🏗️ Directory-Based Loading (IaC Ready)
設定ファイルの読み込みロジックを刷新しました。
- **`common/loader.sh`**: `_*.sh` 形式のファイルをスキャンし、依存関係を考慮して自動読込。
- **Idempotent Deployment**: `install.sh` が環境パスを `.zshrc` へ自動注入。テンプレート方式により、どのディレクトリに clone しても即座に動作します。

### 🧠 Unified AI Ecosystem (llm + Gemini 2.5)
AI 実行エンジンを `llm` に統一。2026年最新の **Gemini 2.5 Flash** をデフォルトモデルとしてプリセットします。
- **`ginv`**: AI への汎用的な問いかけ。
- **`gcm`**: Git 差分から最適なコミットメッセージを提案。

---

## 🏎️ Power Features

| Command | Feature | Description |
| :--- | :--- | :--- |
| `n` | **Nano Magic** | **[NEW]** `fzf` 検索 ＋ 編集時パレット自動変更機能。 |
| `ginv` | **AI Oracle** | Gemini 2.5 による汎用 AI 問いかけツール。 |
| `gcm` | **AI Commit** | 差分解析によるコミットメッセージ生成。 |
| `wtf` | **AI Fixer** | 直前のエラーを解析し、修正案を提示。 |
| `z` | **Fast Jump** | `zoxide` による学習型ディレクトリ高速移動。 |

---

## 📂 リポジトリ構造 (v1.16.0)

- **`install.sh`**: OS自動判別、`__DOTPATH__` 置換、一括セットアップ。
- **`common/`**: 
  - `loader.sh`: 司令塔。各設定ファイルの読込を制御。
  - `_system.sh`: エイリアス、パレット制御、`n` 関数など。
- **`scripts/`**: セットアップのコアロジック。
- **`bin/`**: AI ツール群（`ginv` 等）の実行ファイル。

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
