# 🚀 initrc: The RC Files Recreator

![Version](https://img.shields.io/badge/version-1.3.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

> **"Environment construction in 0 seconds."** > `initrc` は、単なる設定のコピーではありません。実行環境に合わせて設定ファイルを動的に **"Recreate（再生成）"** する、Linuxサーバー管理者のための最強スターターキットです。

---

## 🛠️ "Recreator" としての核心機能

### 1. Dynamic Path Resolution (Smart Nano/Vim)
インストール時の絶対パスを自動検知。root ユーザーでもパスエラーを吐かさない、動的な `.nanorc` 生成ロジックを搭載。どこに clone しても、その場で最適な設定を再構築します。

### 2. Zero-Conflict Shell Integration
- **Cross-Shell Support**: Bash/Zsh 両対応。
- **Auto-Unalias**: 関数の競合（`de`, `dl`, `z` など）を自動で回避。既存のエイリアスに邪魔されず、常に最新のツールセットを展開します。

### 3. Intelligence-Aware UI & Preview
環境内のモダンツール（`eza`, `bat`）を動的に検知。ツールが存在すれば、`zi` コマンドのプレビュー画面に自動で **Tree-view** や **Syntax Highlighting** を適用します。

### 4. All-in-One Tool Auto-Installer
`fzf`, `zoxide`, `bat`,, `ccze` ... 必須ツールがなければその場でインストール。依存関係に悩む時間をゼロにします。

---

## 🏎️ Power Features

| Command | Feature | Description |
| :--- | :--- | :--- |
| `z` / `zi` | **Smart Jump** | `zoxide` による高速移動。`zi` では `eza` 連携のツリープレビューを展開。 |
| `gcm` | **Git Smart Commit** | `fzf` による対話型コミット。メッセージ入力を直感的に。 |
| `dl` / `de` | **Docker Helper** | コンテナログ監視・侵入を `fzf` でリストから選択。 |
| `si` / `ss` | **Safe Root** | root 昇格時の背景色警告。オペレーションミスを視覚的に防止。 |
| `cat` / `ls` | **Modern Replace** | `bat` や `eza` への自動エイリアス。 |

---

## 🚀 クイックスタート

```bash
git clone [https://github.com/rafale2k/initrc.git](https://github.com/rafale2k/initrc.git) ~/dotfiles
cd ~/dotfiles && ./install.sh
