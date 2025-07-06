# https://yomaq.github.io/posts/nvidia-on-nixos-wsl-ollama-up-24-7-on-your-gaming-pc/
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.gpu;
in
{
  options.my.system.gpu = {
    enable = lib.mkEnableOption "Whether to enable gpu support";
    vendor = lib.mkOption {
      type = lib.types.enum [
        "nvidia"
      ];
      default = "nvidia";
      description = "GPU vendor";
    };
    containerSupport = lib.mkEnableOption "Whether to enable container support";
    cdiDir = lib.mkOption {
      type = lib.types.path;
      default = "/etc/cdi";
      description = "Path to the CDI configuration directory. filename will be <vendor>.json";
    };
  };
  config = lib.mkIf cfg.enable (
    lib.mkIf (cfg.vendor == "nvidia")
      {
        services.xserver.videoDrivers = [ "nvidia" ];
        hardware.nvidia.open = true;

        environment.sessionVariables = {
          CUDA_PATH = "${pkgs.cudatoolkit}";
          EXTRA_LDFLAGS = "-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib";
          EXTRA_CCFLAGS = "-I/usr/include";
          LD_LIBRARY_PATH = [
            (lib.mkIf config.wsl.enable "/usr/lib/wsl/lib")
            "${pkgs.linuxPackages.nvidia_x11}/lib"
            "${pkgs.ncurses5}/lib"
          ];
          MESA_D3D12_DEFAULT_ADAPTER_NAME = "Nvidia";
        };

        hardware.nvidia-container-toolkit = {
          enable = cfg.containerSupport;
          mount-nvidia-executables = false;
        };

        systemd.services = lib.mkIf cfg.containerSupport {
          nvidia-cdi-generator = {
            description = "Generate nvidia cdi";
            wantedBy = [ "docker.service" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pkgs.nvidia-docker}/bin/nvidia-ctk cdi generate --output=${cfg.cdiDir}/${cfg.vendor}.yaml --nvidia-ctk-path=${pkgs.nvidia-container-toolkit}/bin/nvidia-ctk";
            };
          };
        };
        virtualisation.docker = let 
          settings = {
            features.cdi = true;
            cdi-spec-dirs = [ cfg.cdiDir ];
          };
        in lib.mkIf cfg.containerSupport {
          daemon.settings = settings;
          rootless.daemon.settings = settings;
        };
      }
  );
}
