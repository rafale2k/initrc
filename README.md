# 🚀 v1.18.0 "Robust Backup" - Release Notes

![Version](https://img.shields.io/badge/version-1.19.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![OS Support](https://img.shields.io/badge/os-macOS%20%7C%20Ubuntu%20%7C%20AlmaLinux-orange)
![CI Status](https://github.com/rafale2k/initrc/actions/workflows/test.yml/badge.svg)
![Uninstaller](https://img.shields.io/badge/uninstaller-supported-brightgreen)
![Linux CI](https://github.com/rafale2k/initrc/actions/workflows/linux-distros.yml/badge.svg)
![AI](https://img.shields.io/badge/AI-Gemini%202.5%20Flash-vibrantblue?logo=google-gemini&logoColor=white)
![LLM](https://img.shields.io/badge/LLM-llm%20integrated-6f42c1?logo=python&logoColor=white)
![Linting](https://img.shields.io/badge/shellcheck-100%25%20passing-brightgreen)
![IaC](https://img.shields.io/badge/concept-IaC%20Ready-lightgrey?logo=terraform&logoColor=623CE4)
![Installer](https://img.shields.io/badge/installer-idempotent-blueviolet)
[![X](https://img.shields.io/badge/X-@rafale-1DA1F2?style=flat&logo=x&logoColor=white)](https://x.com/rafale)

> **"Freedom to install, power to revert. Your environment, now completely portable."**
> `v1.19.0` は、インストール時の設定のバックアップを搭載し、特定のパスに縛られない究極の移植性を手に入れた「完成形」へのマイルストーンです。

---

## 🖼️ Showcase

![initrc Showcase Banner](assets/54.png)

---

## 🏗️ v1.18.0 "The Great Cleanup" - 主な変更点

### 🧹 1. Official Uninstaller Support (`uninstall.sh`)
「入れるのは簡単だが、消すのが面倒」というdotfiles最大の課題を解決しました。
- **Auto-Detect & Revert**: `.zshrc` や `.bashrc` に追記された設定を自動検知し、痕跡を残さず削除します。
- **App/Bin Cleanup**: インストールされた `eza`, `bat`, `fzf` などのバイナリや、Oh My Zsh関連のディレクトリを安全に一括整理します。

### 🌍 2. True Path Portability (No More Hardcoded Paths)
`/home/rafale` といった特定の絶対パスを排除し、環境変数を駆使したポータブルな構造に刷新しました。
- **Dynamic Root Detection**: `common/loader.sh` が、自身が配置されたディレクトリから相対的に `DOTFILES_PATH` を自動割り出しします。
- **Cross-User Ready**: どのユーザー名、どのホームディレクトリ下でも、クローンしてすぐに `install.sh` が動作します。

### ⚡ 3. Optimized Loading Sequence
読み込みログの視認性と処理効率を向上させました。
- **Redundancy Elimination**: 重複していたロードループを一本化し、シェル起動時の無駄を排除。
- **Visual Feedback**: 各モジュールの読み込み状況を `📖 Loading...` ログで明示し、トラブルシューティングを容易にしました。

---

## 🖼️ Features

| Command | Feature | Description |
| :--- | :--- | :--- |
| `uninstall.sh` | **Clean Revert** | **[NEW]** 構築した環境をクリーンな状態に巻き戻します。 |
| `loader.sh` | **Smart Load** | **[NEW]** パス自動計算機能を備えた次世代ローダー。 |
| `ginv` | **AI Oracle** | Gemini 2.5 によるターミナル一体型 AI アシスタント。 |
| `gs` / `ga` / `gc` | **Git Alias** | 爆速で Git 操作を行うための厳選エイリアス。 |
| `reload` | **Instant Sync** | 設定変更を即座に反映（`exec zsh -l` のエイリアス）。 |

---

## 🛠️ 修正された不具合・改善点

| Target | Issue | Solution |
| :--- | :--- | :--- |
| **common/loader.sh** | 設定ファイルが2回ずつ読み込まれる | ロードループを整理し、ガード変数を最適化 |
| **configs/gitconfig** | `safe.directory` の絶対パス依存 | ワイルドカードまたは相対参照による汎用化 |
| **bash/.bashrc** | マージ後のファイル消失（空ファイル化） | Git履歴からの復旧と、上書き防止処理の強化 |
| **System** | インストール後のパス通し重複 | `.zshrc` への PATH 追記ロジックをより厳密に改善 |

---

## 🏎️ アップデート・インストール手順

**新規インストール:**
```bash
git clone [https://github.com/rafale2k/initrc.git](https://github.com/rafale2k/initrc.git) ~/dotfiles
cd ~/dotfiles
./install.sh
```

---

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

© 2026 Rafale / initrc Project.
