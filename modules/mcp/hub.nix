# Need mcp-server-nix as overlays, NOT module.
# Because module generates json file on build, so it's not possible to use it as Nix home-manager configuration.

{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.types;
let
  cfg = config.my.system.mcp;
  mainPkgs = pkgs;
  workingDirectory = "/var/lib/mcpjungle";
  environmentVariablesForProxy = lib.optionals (config.my.system.networks.proxy != "") [
    "https_proxy=${config.my.system.networks.proxy}"
    "HTTPS_PROXY=${config.my.system.networks.proxy}"
  ];
  # All servers in flat structure to prevent duplicate registration
  allServers = lib.flip lib.concatMapAttrs cfg.serverGroupFiles (groupName: groupConfig:
    groupConfig.configFiles or {}
  );
  mcpJungleWithRuntime = pkgs.symlinkJoin {
    name = pkgs.mcpjungle.pname;
    paths = with pkgs; [
      mcpjungle

      # node
      nodejs
      # python
      python3
      uv
      # go
      go
    ];
    nativeBuildInputs = with pkgs; [
      makeWrapper
    ];
    postBuild = ''
      wrapProgram $out/bin/mcpjungle \
        --add-flags "--registry http://${cfg.hub.host}:${builtins.toString cfg.hub.port}"
    '';
  };

  # Original server configuration files (will be transformed at runtime)
  # Use "cut -d, -fN" to separate name and path in shell script
  serverFiles = lib.mapAttrsToList (serverName: serverConfig:
    "${serverName},${serverConfig.configFile}"
  ) allServers;

  # Group to server mapping information
  groupMapping = lib.flip lib.mapAttrs cfg.serverGroupFiles (groupName: groupConfig:
    builtins.attrNames (groupConfig.configFiles or {})
  );

  # Generate group mapping file as derivation
  groupMappingFile = pkgs.writeText "group-mapping.json" (builtins.toJSON groupMapping);
in
{
  options.my.system.mcp.hub = {
    enable = mkEnableOption "Whether to enable MCP hub (mcpjungle).";
    host = mkOption {
      type = str;
      description = "Host for MCP hub server.";
      default = "127.0.0.1";
    };
    port = mkOption {
      description = "Port number of MCP hub";
      type = number;
      default = 3001;
    };
    environmentFiles = mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "List of environment files to source before starting mcpjungle.";
    };
    sharedFiles = mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "List of files to be shared into mcpjungle container.";
    };
  };

  config = lib.mkIf config.my.system.mcp.hub.enable {
    boot.enableContainers = true;
    containers.mcpjungle = {
      autoStart = true;
      bindMounts = lib.listToAttrs (map (f: {
        name = f;
        value = {
          hostPath = f;
          isReadOnly = true;
        };
      }) cfg.hub.sharedFiles);

      config = {config, pkgs, lib, ...}: {
        imports = [ ../core/minimal.nix ];
        system.stateVersion = config.system.nixos.release;

        services.journald.extraConfig = ''
          SystemMaxUse=100M
        '';

        # For CLI
        environment.systemPackages = [
          mcpJungleWithRuntime
        ];

        systemd.services = {
          "mcpjungle-ready" = {
            description = "Ready for mcpjungle";
            serviceConfig = let script = pkgs.writeShellScriptBin "ready-for-mcpjungle" ''
              ${pkgs.coreutils}/bin/mkdir -p ${workingDirectory}/servers
              rm -rf ${workingDirectory}/mcp*.db 2>/dev/null || true
            '';
            in {
              Type = "oneshot";
              ExecStart = "${script}/bin/ready-for-mcpjungle";
            };
            wantedBy = [ "multi-user.target" ];
          };

          "mcpjungle" = rec {
            description = "mcpjungle server";
            startLimitIntervalSec = 120;
            startLimitBurst = 5;
            after = [
              "mcpjungle-ready.service"
            ];
            requires = after;
            serviceConfig = {
              WorkingDirectory = workingDirectory;
              ExecStart = "${mainPkgs.mcpjungle}/bin/mcpjungle start --port ${builtins.toString cfg.hub.port}";
              Environment = environmentVariablesForProxy;
              EnvironmentFile = cfg.hub.environmentFiles;
              Restart = "on-failure";
              RestartSec = 5;
              StateDirectory = "mcpjungle";
              RuntimeDirectory = "mcpjungle";
              RuntimeDirectoryMode = "0755";
              StandardOutput = "journal";
              StandardError = "journal";
            };
            wantedBy = [ "multi-user.target" ];
          };
          "mcpjungle-post-setup" = rec {
            description = "Post setup for mcpjungle";
            requires = [
              "mcpjungle.service"
            ];
            after = requires;
            serviceConfig = let
              jqFilter = pkgs.writeText "mcpjungle-transform.jq" ''
                . as $orig | {
                  name: $name,
                  description: "MCP server: \($name)",
                  transport: (
                    if $orig | has("url") then "streamable_http"
                    elif $orig | has("command") then "stdio"
                    else null end
                  ),
                  url: (if $orig | has("url") then $orig.url else null end),
                  command: (if $orig | has("command") then $orig.command else null end),
                  args: (if $orig | has("args") then $orig.args else null end),
                  env: (if $orig | has("env") then $orig.env else null end),
                  bearer_token: (if $orig | has("bearer_token") then $orig.bearer_token else null end)
                } | del(.[] | nulls)
              '';
              script = pkgs.writeShellApplication {
                name = "setup-mcpjungle";
                runtimeInputs = with mainPkgs; [
                  gnugrep
                  gnused
                  coreutils
                  findutils
                  jq
                  mcpJungleWithRuntime
                  wait-for-it
                  bash
                ];
                excludeShellChecks = [ "SC2016" ];
                text = ''
                  echo "Waiting for mcpjungle to become available..."
                  wait-for-it localhost:${builtins.toString cfg.hub.port} --strict --timeout=30

                  echo "Processing server configurations..."
                  echo "${lib.concatStringsSep "\n" serverFiles}" \
                    | xargs -P4 -I{} bash -c '
                      server_name="$(echo {} | cut -d, -f1)"
                      server_file="$(echo {} | cut -d, -f2)"
                      echo "Processing server: $server_name"

                      # Transform config using jq
                      temp_file="$(mktemp /tmp/mcpjungle-server-$server_name-XXXXXX.json)"
                      jq -c --arg name "$server_name" -f ${jqFilter} "$server_file" > "$temp_file"

                      echo "Registering transformed config: $temp_file"
                      mcpjungle register -c "$temp_file" || true
                      rm -f "$temp_file"
                      '

                  echo "Server registration complete"

                  # Reset Tool Groups
                  echo "Resetting existing groups..."
                  { mcpjungle list groups 2>&1 | grep -E "^[0-9]+.*" | cut -d" " -f 2 \
                    | xargs -I{} mcpjungle delete group {}; } || true

                  # Create Tool Groups based on group mapping
                  group_mapping_file="${groupMappingFile}"
                  echo "Processing group mappings from $group_mapping_file"

                  if [ -f "$group_mapping_file" ]; then
                    # Get all group names
                    groups=$(jq -r 'keys[]' "$group_mapping_file")

                    # Process each group
                    for group_name in $groups; do
                      echo "Creating group: $group_name"
                      # Get server names for this group
                      servers=$(jq -r --arg group "$group_name" '.[$group][]' "$group_mapping_file")
                      tools=()

                      # Collect enabled tools from each server in the group
                      for server_name in $servers; do
                        echo "  Checking tools from server: $server_name"
                        enabled_output=$({ mcpjungle list tools --server "$server_name" 2>&1 | grep "\[ENABLED\]" | cut -d" " -f 2; } || true)
                        if [ -n "$enabled_output" ]; then
                          readarray -O "''${#tools[@]}" -t tools <<< "$enabled_output"
                        fi
                      done

                      # Create group if there are tools
                      if [ ''${#tools[@]} -gt 0 ]; then
                        temp_json="/tmp/''${group_name}-group.json"
                        echo "    Creating group JSON: $temp_json"
                        echo "{\"name\": \"''${group_name}\", \"description\": \"Tool group for ''${group_name}\", \"included_tools\": [" > "$temp_json"
                        for tool in "''${tools[@]}"; do
                          echo "\"''${tool}\"," >> "$temp_json"
                        done
                        sed -i '$ s/,$/]}/' "$temp_json"
                        mcpjungle create group -c "$temp_json" || echo "Failed to create group $group_name"
                        rm -f "$temp_json"
                      else
                        echo "    No enabled tools found for group: $group_name"
                      fi
                    done
                  else
                    echo "Group mapping file not found: $group_mapping_file"
                  fi
                  echo "Group setup complete"
                '';
              };
            in {
              ExecStart = "${script}/bin/setup-mcpjungle";
            };
            wantedBy = [ "multi-user.target" ];
          };
        };
      };
    };
  };
}
