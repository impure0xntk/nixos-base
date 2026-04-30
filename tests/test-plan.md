# NixOS Base Module Test Plan

## 1. Current Status Analysis
- Existing test artifacts:
  - `tests/modules/earlyoom.nix`: Dedicated test suite for the `earlyoom` module
  - `tests/modules/default.nix`: Base VM configuration reused across test suites
- Testing framework: `nixpkgs.lib.nixosTest` for isolated NixOS VM validation
- Standard test structure (derived from `earlyoom.nix`):
  - `name`: Descriptive identifier for the test suite
  - `nodes`: VM configuration section to enable and parameterize the target module
  - `testScript`: Validation logic using `machine.succeed()` (expects exit code 0) and `machine.fail()` (expects non-zero exit code) to verify service state, configuration, and binary availability

## 2. Target Modules
Total: 39 modules (excluding `modules/ai/litellm/models/` subdirectory):
1. `modules/ai/NanoProxy.nix`
2. `modules/ai/bot/default.nix`
3. `modules/ai/compression.nix`
4. `modules/ai/default.nix`
5. `modules/ai/local.nix`
6. `modules/auth/default.nix`
7. `modules/bookmark/default.nix`
8. `modules/certs/default.nix`
9. `modules/chat/default.nix`
10. `modules/clipboard/default.nix`
11. `modules/core/default.nix`
12. `modules/core/memory-management.nix`
13. `modules/core/minimal.nix`
14. `modules/core/ntp.nix`
15. `modules/desktop/autologin/default.nix`
16. `modules/desktop/common/default.nix`
17. `modules/desktop/rdp/default.nix`
18. `modules/develop/common/default.nix`
19. `modules/develop/default.nix`
20. `modules/develop/nix/default.nix`
21. `modules/dns/default.nix`
22. `modules/gpu/default.nix`
23. `modules/management/agent.nix`
24. `modules/management/manager.nix`
25. `modules/mcp/default.nix`
26. `modules/mcp/hub.nix`
27. `modules/mcp/preset-servers.nix`
28. `modules/memo/default.nix`
29. `modules/platform-config/default.nix`
30. `modules/reverse-proxy/default.nix`
31. `modules/rss-feed/default.nix`
32. `modules/secrets-store/default.nix`
33. `modules/security/STIG.nix`
34. `modules/security/default.nix`
35. `modules/security/lynis-recommendations.nix`
36. `modules/task-management/default.nix`
37. `modules/virtualisation/default.nix`
38. `modules/virtualisation/docker/default.nix`
39. `modules/worklog/default.nix`

## 3. Test Structure Template
All new tests must follow the pattern established in `tests/modules/earlyoom.nix`:
```nix
{ nixpkgs, pkgs, lib, system, self, ... }:

pkgs.testers.runNixOSTest {
  name = "<module>-module-tests";

  node.specialArgs = {
    inherit lib;
  };
  nodes.machine = { config, lib, pkgs, ... }: {
    imports = [
      self.nixosModules.${system}.mySystemModules
    ];
    # Enable and configure target module
    <module.config.path> = {
      enable = true;
      # Add module-specific test configuration here
    };
  };
  testScript = ''
    machine.start()
    # 1. Verify service is active when enabled
    machine.succeed("systemctl is-active --quiet <service-name>.service")
    # 2. Verify packaged binaries exist in PATH
    machine.succeed("which <binary-name>")
    # 3. Verify user configuration is applied
    machine.succeed("systemctl cat <service-name>.service | grep -qE '<expected-config-pattern>'")
    # 4. Verify conflicting services are disabled (if applicable)
    machine.fail("systemctl is-active --quiet <conflicting-service>.service")
  '';
}
```

## 4. Mandatory Test Coverage
Every module test must validate at minimum:
1. Service state: Confirm the module's systemd service starts successfully when enabled
2. Binary availability: Confirm the module's packaged executables are present in the system PATH
3. Configuration correctness: Verify user-specified options are reflected in generated configs/services
4. Conflict resolution: Confirm the module disables conflicting services where applicable
5. Negative case: Verify the service does not run when the module is disabled

## 5. Prioritized Implementation Roadmap
Tests will be rolled out in order of module criticality:

### Phase 1: Core System Modules (Highest Priority)
- `modules/core/ntp.nix`: NTP sync verification and configuration validation
- `modules/core/memory-management.nix`: Memory tuning parameter checks
- `modules/core/default.nix`: Base core module functionality
- `modules/core/minimal.nix`: Minimal system boot verification

### Phase 2: Virtualisation & Container Modules
- `modules/virtualisation/docker/default.nix`: Docker service and basic container operations
- `modules/virtualisation/default.nix`: Base virtualisation settings
- `modules/virtualisation/incus/default.nix`: Incus service and instance management

### Phase 3: Security Modules
- `modules/security/default.nix`: Base security hardening checks
- `modules/security/STIG.nix`: STIG compliance configuration validation
- `modules/security/lynis-recommendations.nix`: Lynis hardening rule verification
- `modules/secrets-store/default.nix`: Encrypted secrets storage functionality

### Phase 4: AI & MCP Modules
- `modules/ai/default.nix`: Base AI module configuration
- `modules/ai/local.nix`: Local LLM service availability
- `modules/ai/NanoProxy.nix`: NanoProxy service validation
- `modules/mcp/default.nix`: MCP server module base functionality
- `modules/mcp/hub.nix`: MCP hub service verification
- `modules/mcp/preset-servers.nix`: Preset MCP server deployments

### Phase 5: Desktop & Development Modules
- `modules/desktop/default.nix`: Base desktop environment configuration
- `modules/desktop/common/default.nix`: Common desktop settings validation
- `modules/desktop/autologin/default.nix`: Autologin functionality
- `modules/desktop/rdp/default.nix`: RDP service availability
- `modules/develop/default.nix`: Base development toolchain verification
- `modules/develop/common/default.nix`: Common development settings
- `modules/develop/nix/default.nix`: Nix development environment checks

### Phase 6: Utility Modules
- `modules/dns/default.nix`: DNS configuration validation
- `modules/reverse-proxy/default.nix`: Reverse proxy service verification
- `modules/rss-feed/default.nix`: RSS feed service functionality
- `modules/task-management/default.nix`: Task management service checks
- `modules/clipboard/default.nix`: Cross-device clipboard sync
- `modules/chat/default.nix`: Chat service availability
- `modules/memo/default.nix`: Memo service functionality
- `modules/worklog/default.nix`: Worklog service verification
- `modules/bookmark/default.nix`: Bookmark management checks
- `modules/certs/default.nix`: Certificate management validation
- `modules/auth/default.nix`: Authentication settings verification
- `modules/platform-config/default.nix`: Platform-specific configuration
- `modules/gpu/default.nix`: GPU acceleration settings
- `modules/management/agent.nix`: Management agent service
- `modules/management/manager.nix`: Management manager service
- `modules/ai/bot/default.nix`: AI bot service verification
- `modules/ai/compression.nix`: AI compression settings validation

## 6. References
- Example test implementation: `tests/modules/earlyoom.nix`
- NixOS test driver documentation: https://nixos.org/manual/nixos/stable/#sec-nixos-test-driver
- Module configuration reference: Individual module files under `modules/` for testable options
