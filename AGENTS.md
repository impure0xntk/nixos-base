# nixos-base - AGENTS.md

## Overview

`nixos-base` provides core NixOS modules for the nixos-reactor project.
It includes system-level configurations, services, hardware settings, and core system options that form the foundation for all machines in the nixos-reactor ecosystem.

## Structure

The project is organized into:

- `modules/`: Contains NixOS modules organized by functional categories:
  - Core system modules (`core/`): Essential system configuration
  - AI/ML services (`ai/`): LLM providers, model configurations
  - Development tools (`develop/`): Programming languages, IDEs, SDKs
  - Desktop environments (`desktop/`): GUI environments, display managers
  - Network services (`networks/`): DNS, DHCP, firewall, VPN
  - Security (`security/`): Antivirus, encryption, access control
  - Storage (`storage/`): Filesystems, backup, synchronization
  - Virtualization (`virtualisation/`): Docker, Incus, VMs
  - Utilities (`auth/`, `bookmark/`, `certs/`, etc.): Specialized services
  - Platform-specific configurations (`platform/`): WSL, native-linux, nspawn, vm
  - Home management (`home-management/`): User environment configurations
  - Workflow automation (`workflow/`, `worklog/`): Task tracking, logging
  - Monitoring & notification (`notification/`, `memo/`): Alerts, notes
  - Reverse proxy (`reverse-proxy/`): Web traffic routing
  - Clipboard synchronization (`clipboard/`): Cross-device clipboard
  - RSS feeds (`rss-feed/`): Content aggregation
  - Web scraping (`web-scraping/`): Automated data extraction
  - Web search (`web-search/`): Search engine integration
  - Locales (`locales/`): Internationalization settings
  - Linting (`lint/`): Code quality tools
  - GPU acceleration (`gpu/`): Graphics processing configuration
  - MCP servers (`mcp/`): Model Context Protocol servers
  - Task management (`task-management/`): Kanban, TODO systems
  - Users & groups (`users/`): Account management
  - Environments (`environments/`): Isolated execution contexts
  - Knowledgebase (`knowledgebase/`): Documentation systems
  - Secrets management (`secrets-store/`): Encrypted credential storage
  - Clipboard (`clipboard/`): Cross-device synchronization

- `platform/`: Contains platform-specific configurations:
  - `native-linux/`: Bare metal Linux systems
  - `wsl/`: Windows Subsystem for Linux
  - `nspawn/`: systemd-nspawn containers
  - `vm/`: Virtual machines
  - `virtualbox-guest/`: VirtualBox guest additions

- `flake.nix`: The flake definition that integrates external inputs and defines outputs
- `tests/`: Tests for NixOS modules and configurations
- `README.md`: General project overview

## Development Guidelines

### Module Creation

1. **Location**: Place new NixOS modules in the appropriate subdirectory under `modules/`
2. **Format**: Each module must follow the NixOS module format:
   ```nix
   { config, lib, pkgs, ... }: {
     options = { /* option declarations */ };
     config = { /* implementation */ };
   }
   ```
3. **Options**: Use `lib.mkEnableOption` for boolean feature toggles:
   ```nix
   options.my.module.feature = lib.mkEnableOption "Description";
   ```
4. **Conditional Logic**: Use `lib.mkIf` for conditional configuration:
   ```nix
   config = lib.mkIf cfg.enable { /* configuration when enabled */ };
   ```
5. **Defaults**: Set sensible defaults with `lib.mkDefault` when appropriate
6. **Overrides**: Use `lib.mkForce` sparingly to override inherited values

### Flake Integration

1. **Inputs**: External dependencies are defined in `flake.nix` under `inputs`
2. **Overlays**: Package customizations go through `nix-pkgs` overlay system
3. **Utilities**: Helper functions are imported from `nix-lib`
4. **System Composition**: Modules are composed via `nixosModules.mySystemModules` in flake outputs

### Testing

1. **Location**: Write tests in the `tests/` directory
2. **Framework**: Use the available NixOS testing framework
3. **Validation**: Test both positive and negative cases for options
4. **Integration**: Ensure modules work correctly when composed with others

### Best Practices

1. **Documentation**: Add clear descriptions to all options
2. **Consistency**: Follow existing code style and patterns in the repository
3. **Minimalism**: Enable only necessary services by default
4. **Security**: Follow security best practices for service configurations
5. **Performance**: Consider resource usage in service configurations
6. **Compatibility**: Ensure modules work across different architectures (x86_64-linux, aarch64-linux)

## Critical Notes

- This submodule is used as an input in the main flake (nixos-reactor) via:
  ```nix
  nixos-base.url = "git+file:./submodules/nixos-base";
  ```
- Changes to this submodule may require updating `flake.lock` in the main repository
- The modules are imported in machine configurations via `imports = [...]` in respective machine's `default.nix`
- When modifying core system options, ensure backward compatibility where possible
- Platform-specific configurations should inherit from common configurations when appropriate

## Related Projects

- `nixos-reactor`: Main repository containing machine profiles and flake integration
- `nix-lib`: Utility functions and helper libraries
- `nix-pkgs`: Custom package overlays and derivations
- `home-manager-base`: User-level configurations and applications

For general workflow (issue tracking, etc.), refer to the root AGENTS.md.

<!-- bv-agent-instructions-v2 -->

---

## Beads Workflow Integration

This project uses [beads_rust](https://github.com/Dicklesworthstone/beads_rust) (`br`) for issue tracking and [beads_viewer](https://github.com/Dicklesworthstone/beads_viewer) (`bv`) for graph-aware triage. Issues are stored in `.beads/` and tracked in git.

### Using bv as an AI sidecar

bv is a graph-aware triage engine for Beads projects (.beads/beads.jsonl). Instead of parsing JSONL or hallucinating graph traversal, use robot flags for deterministic, dependency-aware outputs with precomputed metrics (PageRank, betweenness, critical path, cycles, HITS, eigenvector, k-core).

**Scope boundary:** bv handles *what to work on* (triage, priority, planning). `br` handles creating, modifying, and closing beads.

**CRITICAL: Use ONLY --robot-* flags. Bare bv launches an interactive TUI that blocks your session.**

#### The Workflow: Start With Triage

**`bv --robot-triage` is your single entry point.** It returns everything you need in one call:
- `quick_ref`: at-a-glance counts + top 3 picks
- `recommendations`: ranked actionable items with scores, reasons, unblock info
- `quick_wins`: low-effort high-impact items
- `blockers_to_clear`: items that unblock the most downstream work
- `project_health`: status/type/priority distributions, graph metrics
- `commands`: copy-paste shell commands for next steps

```bash
bv --robot-triage        # THE MEGA-COMMAND: start here
bv --robot-next          # Minimal: just the single top pick + claim command

# Token-optimized output (TOON) for lower LLM context usage:
bv --robot-triage --format toon
```

#### Other bv Commands

| Command | Returns |
|---------|---------|
| `--robot-plan` | Parallel execution tracks with unblocks lists |
| `--robot-priority` | Priority misalignment detection with confidence |
| `--robot-insights` | Full metrics: PageRank, betweenness, HITS, eigenvector, critical path, cycles, k-core |
| `--robot-alerts` | Stale issues, blocking cascades, priority mismatches |
| `--robot-suggest` | Hygiene: duplicates, missing deps, label suggestions, cycle breaks |
| `--robot-diff --diff-since <ref>` | Changes since ref: new/closed/modified issues |
| `--robot-graph [--graph-format=json\|dot\|mermaid]` | Dependency graph export |

#### Scoping & Filtering

```bash
bv --robot-plan --label backend              # Scope to label's subgraph
bv --robot-insights --as-of HEAD~30          # Historical point-in-time
bv --recipe actionable --robot-plan          # Pre-filter: ready to work (no blockers)
bv --recipe high-impact --robot-triage       # Pre-filter: top PageRank scores
```

### br Commands for Issue Management

```bash
br ready              # Show issues ready to work (no blockers)
br list --status=open # All open issues
br show <id>          # Full issue details with dependencies
br create --title="..." --type=task --priority=2
br update <id> --status=in_progress
br close <id> --reason="Completed"
br close <id1> <id2>  # Close multiple issues at once
br sync --flush-only  # Export DB to JSONL
```

### Workflow Pattern

1. **Triage**: Run `bv --robot-triage` to find the highest-impact actionable work
2. **Claim**: Use `br update <id> --status=in_progress`
3. **Work**: Implement the task
4. **Complete**: Use `br close <id>`
5. **Sync**: Always run `br sync --flush-only` at session end

### Key Concepts

- **Dependencies**: Issues can block other issues. `br ready` shows only unblocked work.
- **Priority**: P0=critical, P1=high, P2=medium, P3=low, P4=backlog (use numbers 0-4, not words)
- **Types**: task, bug, feature, epic, chore, docs, question
- **Blocking**: `br dep add <issue> <depends-on>` to add dependencies

### Session Protocol

```bash
git status              # Check what changed
git add <files>         # Stage code changes
br sync --flush-only    # Export beads changes to JSONL
git commit -m "..."     # Commit everything
git push                # Push to remote
```

<!-- end-bv-agent-instructions -->
