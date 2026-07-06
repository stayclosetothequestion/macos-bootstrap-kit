# macos-bootstrap-kit

Bootstrap project for setting up a fresh Apple macOS machine as an agent-focused runtime that is still usable as a normal desktop.

## What It Installs

- Homebrew
- Git
- Node.js via `nvm`
- Python via `pyenv`
- Docker CLI, Docker Compose, and Colima
- Claude Desktop
- Claude Code Terminal via npm package `@anthropic-ai/claude-code`
- Codex CLI via npm package `@openai/codex`
- Base CLI tools and desktop apps from `Brewfile`
- Selected macOS preferences: Dock position/size, keyboard repeat, Finder defaults, screenshots folder, and language/input settings

## Fresh macOS Quick Start

If Git is not installed yet, open the repository in a browser, download it as ZIP, unzip it, then run:

```bash
cd ~/Downloads/macos-bootstrap-kit-main
chmod +x bootstrap.sh scripts/export-macos-settings.sh
DRY_RUN=1 ./bootstrap.sh
./bootstrap.sh
```

If Git is already available:

```bash
git clone <repo-url> macos-bootstrap-kit
cd macos-bootstrap-kit
chmod +x bootstrap.sh scripts/export-macos-settings.sh
DRY_RUN=1 ./bootstrap.sh
./bootstrap.sh
```

Replace `<repo-url>` with the actual Git repository URL.

Review the config first:

```bash
less config/bootstrap.conf
less Brewfile
```

Start Colima only when containers are needed:

```bash
colima start --cpu 4 --memory 6 --disk 80
```

Full fresh-install guide:

- `docs/fresh-macos-install.md`

## Files

- `bootstrap.sh` - main idempotent setup script.
- `config/bootstrap.conf` - package versions and personal macOS settings.
- `Brewfile` - Homebrew taps, CLI tools, casks, and Mac App Store apps.
- `docs/tool-selection.md` - requested and recommended tools.
- `docs/fresh-macos-install.md` - instructions for a new macOS machine.
- `docs/monitoring-research.md` - notes on macOS monitoring and Google Cloud logging options.
- `docs/local-runtime-architecture.md` - Docker/Kubernetes/Cloud Run local runtime strategy.
- `scripts/export-macos-settings.sh` - optional local macOS settings snapshot helper.

## Notes

- The script may ask for the macOS administrator password.
- Some settings require logout or restart to fully apply.
- Containers use Docker CLI with Colima by default. Start the VM when needed with `colima start --cpu 4 --memory 6 --disk 80`.
- To start Colima during bootstrap, run `START_COLIMA=1 ./bootstrap.sh`.
- Docker Desktop is optional and left commented in `Brewfile` for full desktop setups.
- Claude Desktop installation uses Homebrew cask `claude`.
- Claude Code Terminal and Codex CLI are installed globally with npm after Node.js is installed.
- A dedicated Codex Desktop cask is left commented in `Brewfile` because availability may depend on the current OpenAI distribution channel.
- Mac App Store installs require `mas` and an authenticated App Store session.

## What Is Left

- Create the remote Git repository and push this project.
- Decide whether to enable optional monitoring tools: `osquery`, `fluent-bit`, `google-cloud-sdk`.
- Decide later whether to automate applying exported keyboard/layout settings.
