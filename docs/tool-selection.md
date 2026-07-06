# Tool Selection

This document keeps the install list simple: tools explicitly requested by the user, and tools recommended for the bootstrap/agent-runtime setup.

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

## Recommended Tools

| Tool | Why it is needed for this project |
|---|---|
| Homebrew | Base package manager for macOS. It makes the machine reproducible by installing tools and apps from one declarative list. |
| Xcode Command Line Tools | Provides compilers, `make`, SDK headers, Git integration, and build primitives required by Homebrew and many dev dependencies. |
| nvm | Keeps the Node.js version explicit and replaceable for agent tools and JavaScript projects. |
| pyenv | Keeps the Python version explicit and avoids relying on Apple's system Python. |
| pipx | Installs Python CLI apps in isolated environments so global Python does not become messy. |
| curl | Standard HTTP client for bootstrap steps, API checks, local service health checks, and diagnostics. |
| jq | JSON processor for shell scripts, Docker output, cloud CLI output, logs, and API responses. |
| ripgrep | Fast code/config search; useful for agents analyzing projects. |
| Docker CLI / Colima | Lean headless container runtime for local agent workloads without Docker Desktop. |
| osquery | Host inventory and audit layer for processes, users, ports, launchd services, installed apps, and selected file changes. |
| fluent-bit | Lightweight log forwarder for sending bootstrap, runtime, osquery, and selected macOS logs to a logging backend. |
| google-cloud-sdk | Google Cloud CLI for future Cloud Run, GKE, Artifact Registry, IAM, logging, and deployment work. |
