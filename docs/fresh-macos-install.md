# Fresh macOS Install Guide

Use this guide on a newly installed Mac.

## Option A: Download From Browser

Use this when Git is not installed yet.

1. Open the GitHub repository page in Safari.
2. Click `Code`.
3. Click `Download ZIP`.
4. Unzip the archive.
5. Open Terminal.
6. Go to the project folder:

```bash
cd ~/Downloads/macos-bootstrap-kit-main
```

7. Make the script executable:

```bash
chmod +x bootstrap.sh scripts/export-macos-settings.sh
```

8. Review what will be installed:

```bash
less Brewfile
less config/bootstrap.conf
```

9. Run a dry run:

```bash
DRY_RUN=1 ./bootstrap.sh
```

10. Run the bootstrap:

```bash
./bootstrap.sh
```

## Option B: Clone With Git

Use this when Git is available.

```bash
git clone <repo-url> macos-bootstrap-kit
cd macos-bootstrap-kit
chmod +x bootstrap.sh scripts/export-macos-settings.sh
DRY_RUN=1 ./bootstrap.sh
./bootstrap.sh
```

Replace `<repo-url>` with the actual Git repository URL.

## Start Containers

The bootstrap installs Docker CLI, Docker Compose, and Colima. It does not start the Colima VM by default.

Start it when needed:

```bash
colima start --cpu 4 --memory 6 --disk 80
```

Or start it during bootstrap:

```bash
START_COLIMA=1 ./bootstrap.sh
```

## After Bootstrap

Restart Terminal, then verify:

```bash
node --version
python --version
docker --version
colima version
claude --version
codex --version
```

Open newly installed desktop apps once if macOS asks for permissions or first-run setup.

## Optional macOS Settings Export

This is not required for the first install flow.

To snapshot current Dock, Finder, language, screenshots, and keyboard-related settings:

```bash
./scripts/export-macos-settings.sh
```

Generated snapshots are local and ignored by Git by default.

