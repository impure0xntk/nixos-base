# nixos-base - AGENTS.md

Instructions for coding agents working in this repository. Follow them exactly; they encode
invariants that are easy to break and hard to debug.

## 1. What this repository is

`nixos-base` is a **library of NixOS modules**. It defines no machine. It ships
`nixosModules.mySystemModules` (everything under `modules/`) and
`nixosModules.mySystemPlatform.<platform>` (one entry per directory under `platform/`), which the
parent flake composes with real machines.

Consumer contract (never rename these outputs):

| Output | Shape | Consumer |
| --- | --- | --- |
| `nixosModules.mySystemModules` | module | `nixos-reactor` (imported by every `nixosConfiguration`) |
| `nixosModules.mySystemPlatform.native-linux` | module | machines declaring a non-WSL platform |
| `nixosModules.mySystemPlatform.wsl` | module | `machines/home-desktop` |
| `nixosModules.mySystemPlatform.nspawn` | module | containers |
| `nixosModules.mySystemPlatform.vm` | module | VMs |
| `nixosModules.mySystemPlatform.virtualbox-guest` | module | VirtualBox guests |
| `checks.<system>.*` | derivations | CI / `nix flake check` |

Every option lives under the **`my.system.*`** namespace. Nothing is declared at the top level of
`config`.

Supported systems: `x86_64-linux`, `aarch64-linux`.

## 2. Repository map

```
flake.nix                # inputs, mySystemModules, mySystemPlatform, checks
tests/
  test-plan.md           # the testing backlog: which of the 39 modules lack tests
  modules/default.nix    # the checks registry — add new test files here
  modules/core/*.nix     # the actual pkgs.testers.runNixOSTest files
modules/<category>/      # one directory per concern; see table below
platform/<name>/         # native-linux, wsl, nspawn, vm, virtualbox-guest, docker (empty placeholder)
.claude/AGENTS.md -> ../AGENTS.md
.github/AGENTS.md, .github/copilot-instructions.md -> ../AGENTS.md
```

`modules/` is **auto-discovered** by `flake.nix` through
`lib.my.listDefaultNixDirs { path = ./modules; }` — one level deep, directories only, each must
contain a `default.nix`. `modules/openclaw/` and `modules/web-scraping/` are intentionally empty
placeholders; the auto-loader skips directories without a `default.nix`.

| Category | What lives there |
| --- | --- |
| `core/` | stateVersion, nix daemon, cgroupv2/panic kernel params, NTP, memory management, minimal base |
| `ai/` | LiteLLM proxy (`ai/default.nix` + `litellm/models.nix`), local providers, `NanoProxy.nix`, context compression, `bot/` |
| `develop/` | language toolchains and helpers (`common/`, `nix/`) |
| `desktop/` | `autologin/`, `common/`, `rdp/` |
| `virtualisation/` | `docker/`, `incus/` |
| `networks/`, `dns/` | network services and resolver |
| `security/` | hardening, `STIG.nix` (CIS/STIG profile), `clamav/` |
| `mcp/` | `hub.nix` (MCP hub service), `preset-servers.nix` (the catalogue of servers) |
| `secrets-store/` | sops-nix wiring |
| `users/`, `auth/`, `certs/`, `locales/`, `gpu/`, `lint/` | small self-contained concerns |
| `home-management/` | homebox asset server + OIDC |
| `platform-config/` | `my.system.platform.type` / `.settings` — see §4 |
| `management/` | `manager.nix`, `agent.nix` |
| `worklog/`, `memo/`, `workflow/`, `task-management/`, `knowledgebase/`, `bookmark/`, `chat/` | productivity features |
| `clipboard/`, `notification/`, `reverse-proxy/`, `rss-feed/`, `web-search/` | integrations |

## 3. Writing a module

```nix
# modules/<category>/<name>.nix  or  modules/<category>/default.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.my.system.<category>;
in
{
  options.my.system.<category> = {
    enable = lib.mkEnableOption "Whether to enable <category>.";
  };

  config = lib.mkIf cfg.enable {
    # implementation
  };
}
```

Non-negotiable conventions:

- **Namespace**: `options.my.system.*` only. One `enable` gate per category, added with
  `lib.mkEnableOption`; the `config` side is wrapped in `lib.mkIf cfg.enable`.
- **Never** enable a service unconditionally. Nothing in this repository is on by default; the
  machine decides.
- **Every option needs a `description`.** Use `lib.mkOption { type = …; default = …;
  description = "…"; }` for anything that is not a plain boolean.
- **Conditional extras**: `lib.optionals`, `lib.optionalAttrs`, `lib.mkIf` — not `if cfg.x then …
  else …` inline in an attribute set position.
- **No secrets in values.** Secrets come from `secrets-store/` (sops-nix) and are referenced as
  paths (`environmentFile = config.sops.templates.…;`, `…SecretFile`). Never inline a token.
- Add sibling modules to the category's `imports` list, or make them a `default.nix` in a
  subdirectory. `modules/ai/default.nix` importing `./local.nix` and `./compression.nix` is the
  reference pattern.

### The infinite-recursion trap (read before touching `core/`)

`modules/core/default.nix` documents a hard-won workaround: `headless` is exposed as
`_module.args` to break the `imports` infinite-recursion cycle (nixpkgs #28791). A related trap is
that **adding a derivation-producing option can force a comment to be "committed"** so a previous
`git` object is still reachable and SOPS/plaintext decryption does not re-derive. If you hit
`error: The overlays argument to nixpkgs must be a list` or an IFD failure that appears only after
an edit, this is why — read the comment at the top of `modules/core/default.nix` before removing
it.

## 4. Platform abstraction

`modules/platform-config/default.nix` derives the valid `my.system.platform.type` values from the
**directory names under `platform/`** (`lib.my.listDirs { path = ../../platform; }`). Consequences:

- Adding `platform/foo/` automatically makes `"foo"` a valid type. The `settings` submodule is
  where foo-specific options are declared, and `platform/foo/default.nix` consumes them.
- `platform/docker/` exists as an empty directory, so `"docker"` is a valid type with no
  implementation. Do not delete it casually — a machine may reference it.
- Set the type **in the machine's config**, never in this repo:
  ```nix
  my.system.platform = { type = "wsl"; };
  ```
- Platform modules must not import each other. Shared behaviour goes in `modules/`.
- `platform/wsl/default.nix` contains WSL-specific workarounds (XDG_RUNTIME_DIR ownership,
  `socat` port forwards, Windows interop). Preserve those comments and their `FIXME`s; they are
  deliberate, not cruft.

## 5. Tests

`checks.<system>` is `import ./tests/modules { inherit nixpkgs pkgs lib system self; }`.
`tests/modules/default.nix` is a registry — a new test only runs if it is listed there.

```nix
# tests/modules/<category>/<name>.nix
{ nixpkgs, pkgs, lib, system, self, ... }:

pkgs.testers.runNixOSTest {
  name = "<name>";
  node.specialArgs = { inherit lib; };
  nodes.machine = { config, pkgs, ... }: {
    imports = [ self.nixosModules.${system}.mySystemModules ];
    my.system.<category>.enable = true;
  };
  testScript = ''
    machine.start()
    machine.succeed("systemctl is-active <unit>")
  '';
}
```

Rules:

- Use `pkgs.testers.runNixOSTest`, `machine.succeed` (exit 0), `machine.fail` (non-zero).
- Set `node.specialArgs = { inherit lib; };` — the modules use `lib.my.*`.
- `my.system.core.mutableSystem = true;` is required in tests that touch the Nix daemon.
- Only the entries in `tests/modules/default.nix` execute; `core-minimal`,
  `core-memory-management`, and `core-ntp` exist but are commented out.
- `tests/test-plan.md` lists the 39 modules that still need tests, plus the intended structure.
  Cross off items there when you add them.

**Known failure — pre-existing.** `nix flake check` in this repository currently fails with
`error: The overlays argument to nixpkgs must be a list` while building `checks.*.core-default`.
This is not caused by your change. Validate with:

```bash
nix eval --no-write-lock-file .#nixosModules.x86_64-linux --apply 'm: builtins.attrNames m'
nix eval --no-write-lock-file .#nixosModules.x86_64-linux.mySystemModules
```

## 6. Validation

```bash
# The submodule's own checks (currently blocked by the known failure above)
nix flake check --impure
nix flake check --impure '.#checks.x86_64-linux.core-default'

# Real integration: build a machine from the parent repo (the check that matters)
cd ../..
nixos-rebuild build --flake ".?submodules=1#nixosConfigurations.<machine>" --impure
nixos-rebuild dry-activate --flake ".?submodules=1#nixosConfigurations.<machine>" --impure
nixos-rebuild show-config --flake ".?submodules=1#nixosConfigurations.<machine>" --impure
```

`--impure` is mandatory in the parent because the submodules are `git+file:` inputs; without it Nix
reads a stale, committed snapshot instead of your working tree. `?submodules=1` includes
uncommitted submodule state.

## 7. Cross-repository impact

- Consumed as `git+file:./submodules/nixos-base` by `nixos-reactor`, and read directly by
  `home-manager-base` for `nix-pkgs.overlays.${system}`.
- Before renaming or removing an option, find every consumer:
  ```bash
  rtk grep -rn "my\.system\.<name>" ../../machines ../../profiles ../../home ../home-manager-base
  ```
- Option renames are breaking changes for every machine config. If a rename is unavoidable, keep
  the old option declared as deprecated and merge it with the new one via `lib.mkAlias` or
  `lib.warn`.
- Commit inside this submodule first, then bump the pointer in the parent repo, then review the
  parent `flake.lock` diff as a separate change.
- Dependencies you may rely on: `nix-lib` (`lib.my.*`), `nix-pkgs` (`pkgs.my.*`, `pkgs.stable`,
  `pkgs.unstable`), `nixos-wsl`, `nix-index-database`, `sops-nix`, `home-manager`. Adding a new
  external input requires a stated reason and a `flake.lock` review.

## 8. Definition of done

A change is complete when:

1. The module is reachable without editing `flake.nix` (directory + `default.nix`, or imported by
   its category's `default.nix`).
2. Everything is gated behind `my.system.*` and is **off by default**.
3. `nixos-rebuild build` for at least one affected machine succeeds from the parent repo.
4. A `runNixOSTest` exists and is registered in `tests/modules/default.nix`, or `tests/test-plan.md`
   is updated to explain why not.
5. No secret value is inlined; sops paths are used.
6. Comments explain *why*, not *what*; no changelog-style comments were appended to the source.
7. The diff touches no unrelated module and no unrelated `flake.lock` entries.
