# 🚀 v1.20.0 - The "All Green" Monokai Edition

![Version](https://img.shields.io/badge/version-1.20.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![OS Support](https://img.shields.io/badge/os-macOS%20%7C%20Ubuntu%20%7C%20Debian%20%7C%20Fedora%20%7C%20AlmaLinux-orange)
![Linux CI](https://github.com/rafale2k/initrc/actions/workflows/linux-distros.yml/badge.svg)
![macOS CI](https://github.com/rafale2k/initrc/actions/workflows/test.yml/badge.svg)

### 🌍 Supported Distributions
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Debian](https://img.shields.io/badge/Debian-D70A53?style=for-the-badge&logo=debian&logoColor=white)
![Fedora](https://img.shields.io/badge/Fedora-51A2DA?style=for-the-badge&logo=fedora&logoColor=white)
![AlmaLinux](https://img.shields.io/badge/AlmaLinux-D4243D?style=for-the-badge&logo=almalinux&logoColor=white)
![macOS](https://img.shields.io/badge/mac%20os-000000?style=for-the-badge&logo=apple&logoColor=white)

---

![AI](https://img.shields.io/badge/AI-Gemini%202.5%20Flash-vibrantblue?logo=google-gemini&logoColor=white)
![LLM](https://img.shields.io/badge/LLM-llm%20integrated-6f42c1?logo=python&logoColor=white)
![Linting](https://img.shields.io/badge/shellcheck-100%25%20passing-brightgreen)
![IaC](https://img.shields.io/badge/concept-IaC%20Ready-lightgrey?logo=terraform&logoColor=623CE4)
![Installer](https://img.shields.io/badge/installer-idempotent-blueviolet)
![Uninstaller](https://img.shields.io/badge/uninstaller-supported-brightgreen)
[![X](https://img.shields.io/badge/X-@rafale-1DA1F2?style=flat&logo=x&logoColor=white)](https://x.com/rafale)

>SRE（Site Reliability Engineering）としての「堅牢性」と「美学」を追求したターミナル環境構築リポジトリです。
>すべてのスクリプトは **Shellcheck** による静的解析をパスしており、エラーに強く、美しい Monokai Dark 環境を提供します。

---

## 🖼️ Showcase

![initrc Showcase Banner](assets/54.png)

---

## 🏗️ v1.20.0 - The "All Green" Monokai Edition - 主な変更点
## 🚀 Concept

- **Reliability First**: `&& ||` 構文の罠を排除し、安全な `if-else` とエラーハンドリングを徹底。
- **Context Awareness**: 一般ユーザーは **Monokai Dark**、rootユーザーは **Tokyo Night**。視覚的に権限を識別。
- **Zero Friction**: `fzf`, `eza`, `bat`, `zoxide` を駆使し、移動・検索・監視の手数を最小化。

---

## 🛠️ The SRE Toolkit (Custom Functions)

日々の運用業務を爆速にする専用関数群です。

### 1. `h` (Smart History)
過去のコマンド履歴を `fzf` で曖昧検索します。
- **特徴**: Monokai カラーでハイライト。選択したコマンドを実行せず「プロンプトに復元」するため、微調整してからの実行が可能。

### 2. `l` (Advanced Monitor)
ログ・プロセス・ポートをこれ一本で監視します。
- `l`: カレントディレクトリの `.log` ファイルを `fzf` で選んで `tail -f`（`ccze` 連携）。
- `l [Port]`: 指定ポートを使用中のプロセスを `sudo lsof` で調査。
- `l [Keyword]`: 実行中のプロセスをキーワード検索。

### 3. `up` (Directory Jumper)
ディレクトリ階層をスマートに遡ります。
- `up 3`: 3階層上に移動。
- `up src`: 親ディレクトリの中から `src` という名前のディレクトリを探してワープ。

### 4. `lt` (Enhanced Tree)
`eza` を使用した高機能ツリー表示です。
- `lt 2`: 2階層までのディレクトリ構造をアイコン・Gitステータス付きで表示。

---

## 🎨 Terminal Colors

| User | Theme | Background | Highlights |
| :--- | :--- | :--- | :--- |
| **General** | Monokai Dark | `#272822` | Pink / Green / Cyan |
| **Root** | Tokyo Night | `#1a1b26` | Blue / Red / Purple |

※ `nano` や `nvim` を閉じた後、背景色が確実に元のテーマへ復元されるよう制御されています。

---

## 📦 Requirements

以下のモダンツールがインストールされている環境で最高のパフォーマンスを発揮します。
- `fzf` (Fuzzy Finder)
- `eza` (Modern `ls`)
- `bat` (Modern `bat`)
- `zoxide` (Modern `cd`)
- `ccze` (Log Colorizer)

---

## 🛡️ Shellcheck Compliance

このリポジトリの全 `.sh` / `.zsh` ファイルは、CI環境にて **Shellcheck** による厳格なチェックをクリアしています。

- **SC2015**: 論理演算子による誤動作を防止。
- **SC2164**: `cd` 失敗時の予期せぬ挙動をハンドリング。
- **SC2016/SC2046**: クォートと変数展開の適正化。

---

## 🏎️ アップデート・インストール手順

**新規インストール:**
```bash
git clone [https://github.com/rafale2k/initrc.git](https://github.com/rafale2k/initrc.git) ~/dotfiles
cd ~/dotfiles
./install.sh
```

**既存環境の更新:**
```bash
git pull origin main
reload
```

**環境の削除 (Uninstaller):**
```bash
./uninstall.sh  
```

---

## 🔑 API Key Setup
- ~/.dotfiles_env に export GEMINI_API_KEY="your_key" を追記。

- エンジンにキーを登録: llm keys set gemini # プロンプトに従い API Key を入力

---

**"Automate like an SRE, look like a Pro."**
© 2026 Rafale / initrc Project.
