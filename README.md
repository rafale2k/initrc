# 🚀 initrc - The Autonomous SRE Framework

![Version](https://img.shields.io/badge/version-1.29.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![OS Support](https://img.shields.io/badge/os-macOS%20%7C%20Ubuntu%20%7C%20Debian%20%7C%20Fedora%20%7C%20AlmaLinux-orange)
![Linux CI](https://github.com/rafale2k/initrc/actions/workflows/linux-distros.yml/badge.svg)

### 🌍 Supported Distributions
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Debian](https://img.shields.io/badge/Debian-D70A53?style=for-the-badge&logo=debian&logoColor=white)
![Fedora](https://img.shields.io/badge/Fedora-51A2DA?style=for-the-badge&logo=fedora&logoColor=white)
![AlmaLinux](https://img.shields.io/badge/AlmaLinux-D4243D?style=for-the-badge&logo=almalinux&logoColor=white)
![macOS](https://img.shields.io/badge/mac%20os-000000?style=for-the-badge&logo=apple&logoColor=white)

---

![AI](https://img.shields.io/badge/AI-Gemini%203%20Flash-vibrantblue?logo=google-gemini&logoColor=white)
![LLM](https://img.shields.io/badge/LLM-llm%20integrated-6f42c1?logo=python&logoColor=white)
![Linting](https://img.shields.io/badge/shellcheck-100%25%20passing-brightgreen)
![IaC](https://img.shields.io/badge/concept-IaC%20Ready-lightgrey?logo=terraform&logoColor=623CE4)
![Installer](https://img.shields.io/badge/installer-idempotent-blueviolet)
![Uninstaller](https://img.shields.io/badge/uninstaller-supported-brightgreen)
[![X](https://img.shields.io/badge/X-@rafale-1DA1F2?style=flat&logo=x&logoColor=white)](https://x.com/rafale)

>SRE（Site Reliability Engineering）としての「堅牢性」と「自己修復」を追求したターミナル環境。
>macOS および主要な Linux ディストリビューションで動作し、ShellCheck を完全にパスした信頼性の高いスクリプト群を提供します。

---

## 🖼️ Showcase

![initrc Showcase Banner](assets/54.png)

---

## 📸 Visual Gallery & Demos

`initrc` の主要な機能と、洗練された開発環境のインターフェースを紹介します。

### 🤖 AI-Driven Release Workflow
`bin/release` コマンドを実行すると、Gemini AI が前回のタグからの差分を自動解析。情熱的なリリースノートを生成し、GitHub と CHANGELOG を一瞬で同期します。
![AI Release Workflow](assets/55.jpg)


### 📋 Universal Clipboard (OSC52 + Native)
SSH 越しでも、ローカル環境でも。`copyfile` や `osc_copy` を使えば、常に「手元のクリップボード」にデータが届きます。OSC52 エスケープシーケンスと OS 標準ツール（pbcopy/clip.exe/xclip）のハイブリッド仕様です。
![Clipboard-Demo](assets/56.jpg)


### 🎨 Deep Blue "Professional" Prompt
Powerlevel10k をカスタマイズし、カレントディレクトリの背景を視認性の高い **Deep Navy (Color 18)** に刷新。ノイズを削ぎ落とし、長時間のコーディングでも集中力を切らさない配色を実現しました。root時には背景色をTokyoNightに、プロンプトに赤背景にROOTと明記しました。
![root-Demo](assets/57.jpg)



---

---

## ✨ What's New (v1.29.0)

- **Intelligent Maintenance Report**: `dcheck` が裏でツールを復旧させた際、次回のログイン時にどのツールを直したか自動報告する機能を追加。
- **Advanced Backup System (bu v2.2)**: `bu diff` による差分確認、`bu restore` による設定の即時復元に対応。
- **Alias Mentoring**: `cd` を使用した際、より高速な `zoxide (z/j)` の利用を適度な頻度で提案する機能を追加。
- **Stability Fixes**: サブモジュールの完全同期、および Zsh におけるパースエラーを修正。

---

## 🛠️ Key Features

### 1. Autonomous Maintenance
- **dcheck**: 1時間おきに裏で環境の整合性をチェック。作業の手を止めずに環境の「腐敗」を防ぎます。
- **Idempotent Installer**: どの環境で何度実行しても、常に最適な状態に収束。

### 2. SRE & Productivity Tools
- **zoxide (j/zi)**: 過去の履歴からディレクトリをインタラクティブに瞬間移動。
- **eza/bat/fd**: 次世代の標準ツールを統合し、視認性と検索速度を極限まで向上。
- **Git Aliases**: `gquick` (一括Push)、`gs` (Status) など、手数を減らすエイリアス群。

### 3. Safety Net
- **bu [file]**: ファイルをいじる前に実行。`~/.dotfiles_backup/manual` にタイムスタンプ付きで保存。
- **bulist**: バックアップ履歴を古い順に一覧表示（eza ソート最適化済み）。

---

## 🤖 AI Assistant (SRE Copilot)
自然言語でシェルを操作する、SRE 専用の AI 関数群。

- **`ask`**: シェルコマンドの生成・実行支援。
- **`dask`**: Docker コンテナのログ解析・トラブルシューティング。
- **`wtf`**: 直前のエラーメッセージの原因と対策を提示。

---

## 📦 Requirements
- `zsh` / `bash`
- `fzf`, `eza`, `bat`, `zoxide`, `fd`, `shellcheck`
- `python3` & `llm` (AI 機能用)

---

## 🎨 Terminal Colors

| User | Theme | Background | Highlights |
| :--- | :--- | :--- | :--- |
| **General** | Monokai Dark | `#272822` | Pink / Green / Cyan |
| **Root** | Tokyo Night | `#1a1b26` | Blue / Red / Purple |

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
