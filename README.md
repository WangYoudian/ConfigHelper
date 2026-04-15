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

Run:

```bash
bash scripts/linux/main.sh
```
