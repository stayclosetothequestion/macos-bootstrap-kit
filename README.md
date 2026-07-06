# macos-bootstrap-kit

This project sets up a fresh macOS machine with the base tools needed for a human-usable AI agent runtime.

What it installs:

| Tool | Purpose |
| --- | --- |
| Homebrew | macOS package manager. |
| Git | Version control and GitHub access. |
| Node.js via `nvm` | JavaScript runtime with switchable versions. |
| Python via `pyenv` | Python runtime with pinned versions. |
| Docker CLI | Command-line interface for containers. |
| Docker Compose | Runs multi-container local services from compose files. |
| Colima | Lightweight headless Docker runtime for macOS. |
| Claude Desktop | Desktop AI assistant app. |
| Claude Code CLI | Terminal-based coding agent. |
| Codex CLI | Terminal-based coding agent. |
| Microsoft Edge | Browser for login, OAuth, GitHub, and web workflows. |
| Telegram | Messaging app for operational communication. |

## Install On A New Mac

Open Terminal, paste this block, and press Enter:

```bash
cd /tmp
curl -L https://github.com/stayclosetothequestion/macos-bootstrap-kit/archive/refs/heads/main.zip -o macos-bootstrap-kit.zip
ditto -x -k macos-bootstrap-kit.zip .
cd macos-bootstrap-kit-main
chmod +x bootstrap.sh
DRY_RUN=1 ./bootstrap.sh
./bootstrap.sh
```

If macOS opens the Xcode Command Line Tools installer, finish that installer first, then run again:

```bash
./bootstrap.sh
```

## After Install

Restart Terminal, then check:

```bash
node --version
python --version
docker --version
colima version
claude --version
codex --version
```
