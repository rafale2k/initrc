# 🚀 initrc: The RC Files Recreator

![Version](https://img.shields.io/badge/version-1.5.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![OS Support](https://img.shields.io/badge/os-Ubuntu%20%7C%20RHEL%20%7C%20macOS-orange)

> **"Environment construction in 0 seconds."**
> `initrc` は、単なる設定のコピーではありません。実行環境（Ubuntu, RHEL, macOS）に合わせてツールを自動調達し、設定ファイルを動的に **"Recreate（再生成）"** する、エンジニアのための最強スターターキットです。

---

## 🛠️ "Recreator" としての核心機能

### 1. Universal Deployer (Multi-OS Support)
`install.sh` が実行環境を自動判別し、適切なパッケージマネージャー (`apt`, `dnf`, `brew`) を選択。`eza`, `fd`, `bat` などのリポジトリ登録からインストールまでを全自動化します。

### 2. Smart Terminal Context (Tokyo Night & Monokai)
通常時は **Tokyo Night** 配色、Nano 編集時のみ **Monokai 背景**へ。視覚的に「編集モード」を認識させる独自のカラー制御を搭載。

### 3. Dynamic Path Resolution
インストール時の絶対パスを自動検知。root ユーザーでもパスエラーを吐かさない、動的な `.nanorc` 生成ロジックを搭載。

### 4. Zero-Conflict Shell Integration
- **Cross-Shell Support**: Bash/Zsh 両対応。
- **Auto-Unalias**: 関数の競合を自動回避し、常に `initrc` 独自のツールセットを展開。

---

## 🏎️ Power Features

| Command | Feature | Description |
| :--- | :--- | :--- |
| `n` | **Smart Nano** | **(New)** 引数なしで `fzf` 起動。プレビュー付きでファイルを探して即編集。 |
| `fe` | **File Explorer** | `fd` + `bat` による高速プレビュー検索。エディタ(Vim等)で開く。 |
| `zi` | **Smart Jump** | `zoxide` による高速移動。`eza` によるツリープレビュー対応。 |
| `la` | **List All** | `eza -a` エイリアス。アイコン付きで隠しファイルまで表示。 |
| `gcm` | **Git Commit** | `fzf` による対話型セマンティックコミット。 |

---

## 📂 リポジトリ構造

- **`install.sh`**: **(Improved)** OS自動判別・依存ツール一括セットアップ
- **`common/`**: 機能別に分割された設定群
    - `_system.sh`: 配色・基本コマンド・モダンツール置換
    - `_navigation.sh`: **(Improved)** `n`, `fe`, `zi` 等の対話型ナビゲーション
    - `_docker.sh` / `_git.sh`: 各ツール専用設定
    - `loader.sh`: コア・ローダー

## 🚀 クイックスタート

```bash
git clone [https://github.com/rafale2k/initrc.git](https://github.com/rafale2k/initrc.git) ~/dotfiles
cd ~/dotfiles && ./install.sh
source ~/.zshrc
```bash

--
© 2026 Rafale / initrc Project.
