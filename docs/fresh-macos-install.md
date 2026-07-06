# Fresh macOS Install Guide

Use this on a newly installed Mac.

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

After install, restart Terminal and check:

```bash
node --version
python --version
docker --version
colima version
claude --version
codex --version
```
