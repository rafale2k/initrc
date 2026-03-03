# 🚀 v1.17.0 "The Idempotency Awakens" - Release Notes

![Version](https://img.shields.io/badge/version-1.17.0-red)
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

> **"Syntax preservation, duplicate eradication. Your environment, now unbreakable."**
> `v1.17.0` は、マルチプラットフォーム（macOS / Ubuntu / AlmaLinux）におけるセットアップの安定性を極限まで高めた、真の「冪等性（Idempotency）」実装モデルです。

---

## 🖼️ Showcase

![initrc Showcase Banner](assets/54.png)

---

## 🏗️ v1.17.0 "The Idempotency Awakens" - 核心の修正

### 🛡️ String-Level Syntax Preservation (Anti-Parse Error)
従来の `sed` による行削除・コメントアウトは、一行で記述された `if/fi` ブロックを破壊し、シェル起動不能に陥るリスクがありました。
- **Non-Destructive Patching**: 既存の `loader.sh` 記述を物理的に削除せず、内部のパス文字列のみを無害化する手法を採用。
- **Parse Safety**: インデントや `fi` の位置を 1 ミリも動かさないため、特に構文にシビアな Zsh 環境でも 100% 安全なデプロイを実現しました。

### 🔄 Multi-Layer Load Guard (Double Lock)
重複カウント問題を根本から断つ、二重のガードレールを搭載。
- **Idempotency Guard**: `common/loader.sh` 内部に `$INITRC_LOADER_LOADED` フラグを実装。万一設定ファイルが多重ロードされても、実処理は一度しか走りません。
- **PATH Check**: `$HOME/bin` や `$HOME/.local/bin` の重複追加を防止。`$PATH` が無限に肥大化する問題を解消しました。

---

### 🤖 1. Next-Gen AI Workflow (ginv / gcm / ask / wtf)
**Gemini 2.5 Flash** をエンジンに採用。プロンプト応答、コミットメッセージ生成、エラー解析をターミナルから爆速で実行。`llm` エコシステムに完全統合されています。

### 📁 2. Structured Configuration (v1.16.0 NEW)
設定ファイルを `common/` ディレクトリに集約し、アルファベット順に自動ロードする **Dynamic Loader** を搭載。機能追加がファイルを置くだけで完結します。

### 🔍 3. Interactive Operations (fzf + bat + eza)
ファイル検索、Docker コンテナ管理。すべてがプレビュー付きのインタラクティブな体験に。Nano Wrapper (`n`) は編集時にパレットを自動変更する職人仕様です。

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

## 🛠️ 修正された不具合

| Target | Issue | Solution |
| :--- | :--- | :--- |
| **AlmaLinux / Ubuntu** | インストール後の `parse error near fi` | 文字列置換による構文保護の実装 |
| **All OS** | `.zshrc` 内の loader 重複（Count: 3） | ユニークマーカー管理とフィルタリングの導入 |
| **macOS** | `setup_ai_tools` 未定義エラー | 関数定義の完全復旧と ShellCheck 準拠 |
| **ShellCheck** | SC2155, SC2168, SC2128 等の警告 | 変数スコープと配列参照の適正化 |

---

## 📂 内部構造の洗練 (v1.17.0)

- **`common/loader.sh`**: ロード済みガードと、環境に依存しないパス解決ロジック（`BASH_SOURCE` / `ZSH_NAME` ハイブリッド）を搭載。
- **`scripts/install_functions.sh`**: `local` 変数の宣言分離や、`&& ||` 連結の解消など、現代的なシェルスクリプトのベストプラクティスを徹底。

---

## 🏎️ アップデート手順

```bash
git pull origin main
./install.sh
exec zsh -l
```

---

## 🔑 API Key Setup
- ~/.dotfiles_env に export GEMINI_API_KEY="your_key" を追記。

- エンジンにキーを登録: llm keys set gemini # プロンプトに従い API Key を入力

---

© 2026 Rafale / initrc Project.
