# 🚀 initrc - The Autonomous SRE Framework

![Version](https://img.shields.io/badge/version-v2.2.1-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![OS Support](https://img.shields.io/badge/os-macOS%20%7C%20Ubuntu%20%7C%20Debian%20%7C%20Fedora%20%7C%20AlmaLinux-orange)
![Linux CI](https://github.com/rafale2k/initrc/actions/workflows/linux-distros.yml/badge.svg)

### 🌍 Supported Distributions
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Debian](https://img.shields.io/badge/Debian-D70A53?style=for-the-badge&logo=debian&logoColor=white)
![Fedora](https://img.shields.io/badge/Fedora-51A2DA?style=for-the-badge&logo=fedora&logoColor=white)
![AlmaLinux](https://img.shields.io/badge/AlmaLinux-D4243D?style=for-the-badge&logo=almalinux&logoColor=white)
![macOS](https://img.shields.io/badge/mac%20os-000000?style=for-for-the-badge&logo=apple&logoColor=white)

---

![AI](https://img.shields.io/badge/AI-Gemini%203%20Flash-vibrantblue?logo=google-gemini&logoColor=white)
![LLM](https://img.shields.io/badge/LLM-llm%20integrated-6f42c1?logo=python&logoColor=white)
![Linting](https://img.shields.io/badge/shellcheck-100%25%20passing-brightgreen)
![IaC](https://img.shields.io/badge/concept-IaC%20Ready-lightgrey?logo=terraform&logoColor=623CE4)
![Installer](https://img.shields.io/badge/installer-idempotent-blueviolet)
![Uninstaller](https://img.shields.io/badge/uninstaller-supported-brightgreen)
[![X](https://img.shields.io/badge/X-@rafale-1DA1F2?style=flat&logo=x&logoColor=white)](https://x.com/rafale)

> **"Hope is not a strategy."（希望は戦略やない）**
> SREとしての「堅牢性」と「自己修復」を追求した、AI駆動型の開発・運用環境。
> v1.31.0 より、Docker Hub を通じた **「ポータブルな城」** としての配布を開始しました。

---

## 📖 目次
- [🖼️ Visual Gallery & Demos](#️-visual-gallery--demos)
- [✨ Key Features](#-key-features)
- [🗂️ Architecture](#️-architecture)
- [📋 Command Reference](#-command-reference)
- [🚀 Quick Start](#-quick-start)
- [⚙️ Requirements & Colors](#️-requirements--colors)
- [🚀 Latest Updates (Changelog)](#-latest-updates)

---

## 🖼️ Visual Gallery & Demos

| 🤖 AI Release Workflow | 📋 Universal Clipboard | 🎨 Deep Blue Prompt |
| :--- | :--- | :--- |
| ![AI Release Workflow](./assets/55.jpg) | ![Clipboard-Demo](./assets/56.jpg) | ![root-Demo](./assets/57.jpg) |
| `bin/release` でAIが差分を解析。情熱的なリリースノートをGitHubと同期。 | SSH越しでもOSC52対応で「手元のクリップボード」に瞬時に届く。 | Navy背景で集中力を。Root時はTokyoNightへの変化で視覚的に警告。 |

---

## ✨ Key Features

### 🛡️ Autonomous Maintenance（自律保守）
シェルを開くたびに `dcheck` がバックグラウンドで走り、ツールの欠落を自動補修します。SREの第一原則「Hope is not a strategy」を体現。

- **`dcheck`**: 1時間ごとにバックグラウンドで `eza`/`bat`/`fd`/`zoxide`/`fzf`/`tree` の存在を検証。欠落があれば `install_all_packages` を自律実行し、次回ログイン時に `show_maintenance_report` で通知。
- **Idempotent Installer** (`install.sh`): `apt` / `dnf` / `brew` / `apk` を自動判別してパッケージを投入。何度実行しても冪等。バイナリが見つからない場合は GitHub Releases から直接ダウンロードするフォールバック付き。
- **Safety Net** (`bu`): `bu [file]` でタイムスタンプ付きバックアップ。`bu diff` で最新バックアップとの差分表示、`bu restore` で即時復元。30日超の古いバックアップは自動削除。

### 🤖 SRE AI Copilot（AI 連携）
`llm` + Gemini 3 Flash を核とした SRE 専用 AI 関数群。すべて **確認プロンプト付き**で安全に実行できます。

- **`ask 'query'`**: 自然言語をシェルコマンドに変換→確認→実行。
- **`wtf [error]`**: エラーログをAIが解析し、修正方法を Markdown で提示。引数なしでクリップボードか直前のコマンドを自動取得。
- **`dask 'task'`**: `docker compose` のログ・ステータスをコンテキストとして付加してAIに問い合わせ。
- **`kask 'task'`**: 現在の K8s namespace・失敗中の Pod・Error イベントをコンテキストとして付加。
- **`dinv [container] [path]`**: コンテナ内のファイルをSRE視点（設定ミス・セキュリティリスク・パフォーマンス）で診断。
- **`greview`**: `git diff --cached` の内容をAIが日本語でコードレビュー。

### 🧭 Smart Navigation（インテリジェント移動）
- **`j`**: `zoxide` のインタラクティブ検索（`zi` 経由・fzf連携）。よく行くディレクトリに一瞬で飛べる。
- **`fcd`**: `fd` + `fzf` + `eza` プレビューでディレクトリをインクリメンタル検索。
- **`fe`**: ファイルを `fzf` + `bat` プレビューで選択し、ディレクトリなら `cd`、ファイルなら `nano` で開く。
- **`h`**: コマンド履歴を `fzf` で検索。zsh では選択内容をコマンドライン補完、bash ではクリップボードに転送。

### 🌍 Environment-Aware（環境自動識別）
ログイン時に `ENV_ICON` が自動設定され、プロンプトに常に「今どこにいるか」が表示されます。

| アイコン | 環境 |
| :---: | :--- |
| 🐳 | Docker コンテナ |
| 🪟 | WSL (Windows Subsystem for Linux) |
| 🍓 | Raspberry Pi |
| ☁️ | クラウド系ホスト |
| 🏠 | ローカル物理マシン |

### ⚡ Next-Gen Tooling（次世代ツール群）
`zoxide`, `eza`, `bat`, `fd`, `fzf` を高度にカスタマイズして統合。Ubuntu/Debian の `batcat`/`fdfind` 問題も自動解決し、`~/bin` にシムリンクを張ります。Root ログイン時は eza が使えない場合のフォールバックも完備。

---

## 🗂️ Architecture

```
~/dotfiles/
├── common/           # bash / zsh 共通ロジック（loader.sh が一括 source）
│   ├── loader.sh     # エントリポイント: PATH 設定 → _*.sh 読み込み → シェル別設定
│   ├── _ai_assist.sh # ask / wtf / dask / kask / dinv
│   ├── _backup.sh    # bu / eb (バックアップ管理)
│   ├── _docker.sh    # de / dl / drm / dce / dps 等
│   ├── _env_detector.sh # OS/PM 判定 + ENV_ICON
│   ├── _git.sh       # g / gquick / greview / gtoday 等
│   ├── _help.sh      # ha / hall (エイリアス検索)
│   ├── _navigation.sh # up / fcd / fe / h / zoxide
│   ├── _notifications.sh # 起動時メンテナンスレポート表示
│   ├── _suggestions.sh # cd 時の zoxide 使用ヒント
│   └── _system.sh    # ls/ll/cat 置換 / clipboard / l / n / lt
├── bash/
│   ├── .bashrc       # bash エントリポイント → loader.sh → options.sh
│   └── options.sh    # Oh My Bash + 履歴設定 + root 専用エイリアス
├── zsh/
│   ├── .zshrc        # zsh エントリポイント → Oh My Zsh → loader.sh
│   ├── options.zsh   # setopt / zstyle / keybind (ESC×2 で sudo 付加)
│   └── hooks.zsh     # precmd (Monokai 復元) / preexec (レイテンシ計測)
├── bin/              # スタンドアロン実行スクリプト
│   ├── ginv          # llm + Gemini 直接呼び出しラッパー
│   ├── release       # AI 駆動リリースノート生成
│   ├── ask / wtf     # シェルから直接呼べるラッパー
│   └── aic / eza     # AI チャット / eza バイナリ
├── scripts/
│   ├── install_functions.sh  # パッケージ導入・Oh My Zsh・AI ツール等
│   ├── self_heal.sh  # dcheck: バックグラウンド自己修復
│   └── log_wizard.py # lz: ログ解析ウィザード
└── configs/          # gitconfig / vimrc / nanorc / inputrc
```

**ロード順序（zsh）**: `.zshrc` → Oh My Zsh → `common/loader.sh` → `common/_*.sh`（アルファベット順） → `zsh/options.zsh` → `zsh/hooks.zsh`

**ロード順序（bash）**: `.bashrc` → `common/loader.sh` → `common/_*.sh` → `bash/options.sh`

---

## 📋 Command Reference

> 💡 **まず `ha` を試してください。** fzf でエイリアス・関数を全検索し、選択したコマンドを即実行できます。

```bash
ha      # エイリアス・関数をインクリメンタル検索して実行
hall    # エイリアス・関数を色付きで一覧表示
```

### 🤖 AI Copilot

| コマンド | 説明 |
| :--- | :--- |
| `ask 'ls の使い方教えて'` | 自然言語→コマンド生成→確認→実行 |
| `wtf` | クリップボード or 直前のエラーをAIが解析 |
| `dask 'ログが急増した原因は？'` | Docker ログ・ステータス付きで AI に問い合わせ |
| `kask 'Pod が再起動し続ける'` | K8s イベント・Pod 状態付きで AI に問い合わせ |
| `dinv [container] /etc/nginx/nginx.conf` | コンテナ内ファイルをSRE視点で診断 |
| `greview` | staged diff を AI が日本語でコードレビュー |
| `lz` | `log_wizard.py` でログファイルを対話的に解析 |

### 🧭 Navigation

| コマンド | 説明 |
| :--- | :--- |
| `j` | zoxide インタラクティブ検索（fzf）で高速移動 |
| `z <dir>` | zoxide で学習済みディレクトリに移動 |
| `fcd` | fd + fzf + eza プレビューでディレクトリ選択 |
| `fe` | ファイル/ディレクトリを fzf で選択→open |
| `h` | コマンド履歴を fzf で検索・補完 |
| `up 3` / `...` | 3階層上に移動 |
| `up project` | 名前で親ディレクトリに直接ジャンプ |

### 🔧 Git

| コマンド | 説明 |
| :--- | :--- |
| `g` | ブランチ状態・変更差分・直近コミットをサマリ表示 |
| `gquick 'msg'` | add -A → commit → push を一発実行 |
| `gtoday` | 今日の自分のコミット一覧（git-standup 対応） |
| `greview` | staged 差分を AI がコードレビュー |
| `gms` | stash → main に戻る → pull → stash pop |
| `gcl` | マージ済みローカルブランチを一括削除 |
| `ggraph` | カラフルなブランチグラフを表示 |

### 🐳 Docker

| コマンド | 説明 |
| :--- | :--- |
| `dps` | コンテナ状態を色付き表示（Up=緑 / Exited=赤） |
| `de [name]` | fzf でコンテナ選択 → `exec -it /bin/bash` |
| `dl [name]` | fzf でコンテナ選択 → `logs -f --tail 100` |
| `dce` | Compose サービスを選択 → `exec` |
| `drm` | fzf 複数選択 → stop & rm |
| `dri` | 未使用イメージを fzf 選択 → `rmi` |
| `dclean` | 停止コンテナ・未使用ネットワーク・ダングリング削除 |
| `dim` | イメージをサイズ順に表示 |

### 💾 Backup

| コマンド | 説明 |
| :--- | :--- |
| `bu [file]` | タイムスタンプ付きバックアップ作成 |
| `bu diff [file]` | 最新バックアップとの diff 表示 |
| `bu restore [file]` | 最新バックアップから復元（確認プロンプト付き） |
| `bulist` | バックアップ一覧を eza で表示 |
| `eb [file]` | バックアップ作成 → nano で即編集 |

### 🖥️ System

| コマンド | 説明 |
| :--- | :--- |
| `l` | ログファイルを fzf 選択して `tail -f`、引数なしで `htop` |
| `l [port]` | 指定ポートを使用しているプロセスを表示 |
| `l [name]` | プロセス名でフィルタして表示 |
| `n` | fzf + bat プレビュー付き nano ファイル選択 |
| `lt [depth]` | eza によるツリー表示 |
| `copyfile [file]` | ファイル内容をクリップボードにコピー（OSC52 + native） |
| `copypath [path]` | パスをクリップボードにコピー |
| `myip` | 外部 IP アドレスを表示 |
| `ports` | LISTEN 中のポート一覧 |
| `du10` | カレントディレクトリのサイズ上位10件 |

---

## 🚀 Quick Start

### 🐳 Docker (Recommended)
インストール不要。Docker さえあれば、一瞬で「城」を召喚できます。

```bash
docker run -it --rm \
  --group-add $(stat -c '%g' /var/run/docker.sock 2>/dev/null || echo 0) \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e LLM_GEMINI_KEY="あなたのGEMINI_API_KEY" \
  rafale2k/initrc:latest
```

### 🏎️ Traditional Installation
```bash
git clone https://github.com/rafale2k/initrc.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

インストール後:
```bash
exec zsh -l   # 新しい環境を即反映
ha            # 使えるコマンドを fzf で探す
```

---

## ⚙️ Requirements & Colors

- **OS**: macOS / Ubuntu / Debian / Fedora / AlmaLinux
- **Tools**: `zsh`, `python3`, `fzf`, `eza`, `bat`, `zoxide`（インストーラが自動解決）
- **AI**: `llm` + `llm-gemini` プラグイン、`LLM_GEMINI_KEY` 環境変数
- **Themes**:
    - **General**: Monokai Dark (`#272822`)
    - **Root**: Tokyo Night (`#1a1b26`)

---

## 🚀 Latest Updates
<!-- RELEASE_NOTES_START -->

## [v2.2.1] - 2026-06-06
- quick update: 2026-06-06 04:18:52 (5924429)
- chore: update badge to 2.2.0 and regenerate OGP (d5c63ed)
- chore: update badge to 2.2.0 and regenerate OGP (0c3a45c)
- chore: release v2.2.0 (cfb331c)
- chore(deps): bump zsh/plugins/history-search-multi-word (ce739f7)

<!-- RELEASE_NOTES_END -->

---

**"Automate like an SRE, look like a Pro."**
© 2026 Rafale / initrc Project.
