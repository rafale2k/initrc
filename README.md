# 🚀 initrc: The RC Files Recreator

![Version](https://img.shields.io/badge/version-1.9.0-red)
![License](https://img.shields.io/badge/license-MIT-green)
![OS Support](https://img.shields.io/badge/os-Ubuntu%20%7C%20AlmaLinux(RHEL)%20%7C%20macOS-orange)

> **"Environment construction in 0 seconds, across any shell & environment."** > `initrc` は、単なる設定のコピーではありません。実行環境（Local / SSH / Docker）に合わせてツールを自動調達し、クリップボードやパスを動的に **"Recreate（再生成）"** する、エンジニアのための最強スターターキットです。

---

## 🖼️ Showcase

### 🔍 1. Interactive File Search (n / fe)
`fzf` + `bat` による高速プレビュー検索。エディタを開く前に中身を瞬時に確認。
![Smart Search](assets/51.jpg)

### 🌳 2. Smart Navigation (zi) / Jump (z)
`zoxide` が移動履歴を学習。`z` でディレクトリ間を瞬間移動し、`zi` でツリープレビューしながら着地。
![Navigation Preview](assets/52.jpg)

### 📋 3. Universal Clipboard (copyfile)
Docker コンテナやリモートサーバーから、ホスト側のクリップボードへ。OSC 52 シーケンスにより、環境の壁を超えたコピーを実現。

---

## 🛠️ "The Silent Entity" - 核心機能 (v1.9.0 Update)

### ⚡ Zero-Enter Installer
`install.sh` を大幅に刷新。OS自動判別（Debian/RHEL系）はもちろん、SSH鍵生成や Git Identity (`Jane Doe`) の設定を全自動化。一度実行すれば、コーヒーを飲んでいる間に環境が整います。

### 🌐 Universal Clipboard Integration (OSC 52)
`copyfile` が進化。`xclip` や `pbcopy` が使えない Docker / SSH 環境でも、ターミナルのエスケープシーケンスを利用してホスト側のクリップボードへデータを転送。`Oh My Zsh` プラグインの上書きも完全にガード。

### 🐳 Next-Gen Docker Workflow
`de` (Exec), `dl` (Logs), `dce` (Compose Exec) コマンドが `fzf` と連携。
コンテナ名やサービス名を覚えなくても、一覧から選択して即座にダイブ。ステータス表示 (`dps`) も色付きで視認性を極限まで高めました。

### 🤖 AI-Driven Commit (gcm)
`gcm` コマンドが Git の差分を解析し、**AI (Gemini) が最適なコミットメッセージを自動生成**。意味のある履歴を、考える時間をゼロにして構築します。

---

## 🏎️ Power Features

| Command | Feature | Description |
| :--- | :--- | :--- |
| `gcm` | **AI Commit** | AIによるコミットメッセージ自動生成。差分から文脈を読み取ります。 |
| `copyfile` | **Universal Copy** | **(v1.9.0)** Docker/SSH越しにホストのクリップボードへ。 |
| `z` | **Fast Jump** | **(v1.9.0)** 学習型ディレクトリ移動。zoxide による爆速遷移。 |
| `de` / `dl` | **Docker Fzf** | 実行中コンテナを `fzf` で選んで Exec または Logs 表示。 |
| `gstat` | **Git Summary** | プロジェクトの統計、作成日、貢献者リストを瞬時に表示。 |
| `n` | **Smart Nano** | プレビュー検索から即座に編集開始。TokyoNight配色同期。 |
| `reload` | **Quick Refresh** | 設定を再読み込み。p10k の読み込み順を完全制御。 |

---

## 📂 リポジトリ構造

- **`install.sh`**: **(Core)** OS自動判別・依存ツールの一括セットアップ & Zero-Enter 自動化
- **`common/`**: 機能別に分割された設定群
    - `_system.sh`: **(v1.9.0)** OSC 52 連携クリップボード関数 `clipcopy` 搭載
    - `_docker.sh`: fzf 連携コンテナ管理 & カラーエイリアス
    - `_git.sh`: **gcm (AI Commit)** & Git-extras 連携
    - `loader.sh`: 全設定を統合するインテリジェント・ローダー
- **`zsh/` / `bash/`**: シェル固有設定。p10k と自作関数の読み込み順序を最適化。

---

## 🚀 クイックスタート

```bash
git clone --recursive [https://github.com/rafale2k/initrc.git](https://github.com/rafale2k/initrc.git) ~/dotfiles
cd ~/dotfiles && ./install.sh
```
🔑 API Key Setup (for gcm)
gcm (AI Commit) を使用するには Gemini API キーが必要です。

ひな形をコピー: cp ~/dotfiles/common/.env ~/dotfiles/common/.env.local

.env.local を開き、自身の API キーを貼り付け
---
© 2026 Rafale / initrc Project.
