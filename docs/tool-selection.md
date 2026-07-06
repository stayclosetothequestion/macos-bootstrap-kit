# Tool Selection

This document keeps the install list intentionally small: only tools required for a fresh macOS agent-runtime setup.

## Requested Tools

| Tool | Description |
|---|---|
| Git | Version control for projects and bootstrap changes. |
| Node.js | JavaScript runtime for agent tools, web apps, CLIs, and local services. |
| Python | Python runtime for scripts, automation, data tools, and agent projects. |
| Docker | Container runtime for isolating agent-run projects and services. |
| Claude Desktop | Desktop AI assistant app. |
| Claude Code CLI | Terminal-based AI coding assistant. |
| Codex CLI | Terminal-based AI coding assistant. |
| Codex Desktop | Desktop Codex app, if available through the current distribution channel. |
| Microsoft Edge | Browser requested for daily use and web testing. |
| Telegram | Messaging app requested for chat. |

## Minimal Supporting Tools

| Tool | Why it is needed for this project |
|---|---|
| Homebrew | Base package manager for macOS. It makes the machine reproducible by installing tools and apps from one declarative list. |
| Xcode Command Line Tools | Provides compilers, `make`, SDK headers, Git integration, and build primitives required by Homebrew and many dev dependencies. |
| nvm | Keeps the Node.js version explicit and replaceable for agent tools and JavaScript projects. |
| pyenv | Keeps the Python version explicit and avoids relying on Apple's system Python. |
| pipx | Installs Python CLI apps in isolated environments so global Python does not become messy. |
| Docker CLI / Colima | Lean headless container runtime for local agent workloads without Docker Desktop. |

## Excluded From Minimal Setup

| Tool | Why it is excluded |
|---|---|
| Google Chrome | Microsoft Edge is enough as the single default browser for login and web workflows. |
| VS Code | Useful for humans, but not required for a terminal-first agent runtime. |
| curl via Homebrew | macOS already includes system `curl`, which is enough for bootstrap downloads. |
| jq | Useful for shell JSON work, but not required; agents can use Python or Node.js. |
| ripgrep | Useful for fast search, but Claude Code usually includes its own search dependency. |
| fd | Convenient replacement for `find`, but not required for agents. |
| iTerm2 | Human terminal convenience; standard Terminal is enough. |
| Rectangle | Human window-management convenience. |
| wget | Duplicates system `curl` for our use case. |
| fzf | Interactive human convenience, not an agent runtime requirement. |
| tree | Nice directory overview, but not required. |
| htop | Manual process monitoring, not required for bootstrap. |
| mas | Not needed because the setup does not install Mac App Store apps. |

## Future Optional Tools

Enable these only after deciding on monitoring and Google Cloud deployment:

| Tool | Why it may be added later |
|---|---|
| osquery | Host inventory and audit layer for processes, users, ports, launchd services, installed apps, and selected file changes. |
| fluent-bit | Lightweight log forwarder for sending bootstrap, runtime, osquery, and selected macOS logs to a logging backend. |
| google-cloud-sdk | Google Cloud CLI for future Cloud Run, GKE, Artifact Registry, IAM, logging, and deployment work. |
