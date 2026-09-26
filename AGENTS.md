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
