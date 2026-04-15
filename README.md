# ConfigHelper

ConfigHelper is designed to provide one-click setup for commonly used tools on both Windows and Linux.

## Workflow

### Phase 1: Install tool sets
- Select and install predefined development stacks.
- Example stacks:
  - Python + Node.js
  - Java
  - Go + Kubernetes + Docker

### Phase 2: Configure environment and enhancements
- Detect installed tools and configure environment variables automatically.
- Supported tools include (but are not limited to):
  - conda
  - python
  - node
  - java
  - go
  - kubelet
- Apply additional quality-of-life setup such as:
  - beautify / formatting helpers
  - auto-completion

## Linux MVP (started)

- Entry script: `scripts/linux/main.sh`
- Modules:
  - `scripts/linux/toolsets.sh` (Phase 1 toolset installation)
  - `scripts/linux/configure_env.sh` (Phase 2 environment setup)
  - `scripts/linux/verify.sh` (post-setup verification)

Run:

```bash
bash scripts/linux/main.sh
```

Non-interactive examples:

```bash
# Install Python+Node, run configure, then verify
bash scripts/linux/main.sh --toolset python-node --verify --yes

# Only run Phase 2 configure + verify
bash scripts/linux/main.sh --skip-install --verify

# Show usage
bash scripts/linux/main.sh --help
```
