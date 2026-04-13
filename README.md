# 🚀 initrc - The Autonomous SRE Framework

![Version](https://img.shields.io/badge/version-v1.37.1-blue)
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

> **"Hope is not a strategy."（希望は戦略やない）**
> SREとしての「堅牢性」と「自己修復」を追求した、AI駆動型の開発・運用環境。
> v1.31.0 より、Docker Hub を通じた **「ポータブルな城」** としての配布を開始しました。

---

## 📖 目次
- [🖼️ Visual Gallery & Demos](#️-visual-gallery--demos)
- [✨ Key Features](#-key-features)
- [🚀 Quick Start (Usage)](#-quick-start)
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

### 🛡️ Autonomous Maintenance (自律保守)
- **`dcheck`**: 1時間おきに裏で環境の整合性をチェック。作業の手を止めずに環境の「腐敗」を自動で防ぎます。
- **Idempotent Installer**: どの環境で何度実行しても、常に最適な状態に収束。
- **Safety Net**: `bu [file]` で瞬時にバックアップ。`~/.dotfiles_backup` で一元管理。

### 🤖 SRE AI Copilot (AI 連携)
自然言語でシェルを操作する、SRE専用のAI関数群。
- **`ask`**: コマンドの生成・実行支援。
- **`wtf`**: 直前のエラーメッセージの原因と対策をAIが即座に提示。
- **`dask`**: Dockerコンテナのログ解析・トラブルシューティング。

### ⚡ Next-Gen Tooling (次世代ツール群)
`zoxide`, `eza`, `bat`, `fd`, `fzf` を高度にカスタマイズして統合。視認性と検索速度を極限まで向上させています。

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

---

## ⚙️ Requirements & Colors

- **OS**: macOS / Ubuntu / Debian / Fedora / AlmaLinux
- **Tools**: `zsh`, `python3`, `fzf`, `eza`, `bat`, `zoxide`
- **Themes**:
    - **General**: Monokai Dark (`#272822`)
    - **Root**: Tokyo Night (`#1a1b26`)

---

## 🚀 Latest Updates
<!-- RELEASE_NOTES_START -->

## [v1.37.1] - 2026-04-14

> ### 🤖 AI Release Summary
> Dockerfileを徹底解体・再構築！可読性を極限まで高め、運用の安定性を次元上昇させました！🐳
サブモジュールと開発環境を最新へ！微細な改善の積み重ねが、鉄壁の信頼性を生みます！🚀
磨き上げられたコードこそがSREの魂！この洗練された基盤で、システムの未来を熱く切り拓きます！🔥

---
- refactor(docker): Enhance Dockerfile readability with splits (54311e4)
- Update submodules (0954fa7)
- chore: release v1.36.2 (9519a15)
- quick update: 2026-04-01 00:57:42 (c5ca477)
- chore: release v1.36.2 (73260bd)

<!-- RELEASE_NOTES_END -->

---

**"Automate like an SRE, look like a Pro."**
© 2026 Rafale / initrc Project.
