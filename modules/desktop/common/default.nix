# inspire: https://github.com/marcinfalkiewicz/nixos-configuration/blob/master/pkgs.nix
{ config, pkgs, lib, ... }:
let
  cfg = config.my.system.desktop;
  cfgSystem = config.my.system;
in {
  options.my.system.desktop = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = !cfgSystem.core.headless;
      description = "Whether to enable desktop environment.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.xserver = {
      # autorun does no longer work. https://github.com/NixOS/nixpkgs/issues/311683
      enable = true;
    };

    # login manager
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --asterisks --time --remember --remember-session --cmd 'sx'";
        };
      };
      vt = 7; # required for display session(tty7)
    };
    # startx cannot work with SCUDO memory allocator, so replace to sx.
    services.xserver.displayManager.sx.enable = true;
    services.xserver.displayManager.lightdm.enable = lib.mkForce false;

    programs.dconf.enable = true;
    services.xserver.excludePackages = with pkgs; [
      xterm
    ];
    xdg.portal.enable = false; # backend is defined in each flavor nix.

    # sound. https://nixos.wiki/wiki/PipeWire
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      # jack.enable = true;
    };
    services.pulseaudio.enable = lib.mkForce false; # to avoid conflicts with pipewire

    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        addons = with pkgs; [ fcitx5-mozc ];
        # /etc/xdg/fctix5/profile
        # https://qiita.com/tohka383/items/eb7ac2e9a55305356fa8#%E3%82%A4%E3%83%B3%E3%83%97%E3%83%83%E3%83%88%E3%83%A1%E3%82%BD%E3%83%83%E3%83%89%E3%81%AE%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB%E8%A8%AD%E5%AE%9A
        settings.inputMethod = {
          "Groups/0" = {
            "Name" = "Group 0";
            "Default Layout" = config.services.xserver.xkb.layout;
            "DefaultIM" = "mozc";
          };
          "Groups/0/Items/0" = {
            "Name" = "keyboard-${config.services.xserver.xkb.layout}";
            "Layout" = "";
          };
          "Groups/0/Items/1" = {
            "Name" = "mozc";
            "Layout" = "";
          };
          "GroupOrder" = {
            "0" = "Group 0";
          };
        };
      };
    };
    nixpkgs.overlays = lib.optionals (config.i18n.inputMethod.type == "fcitx5") [
      (final: prev: {
        # fcitx5-configtool depends plasma and it's too heavy, so disable fcitx5-configtool
        # https://github.com/azuwis/nix-config/blob/4fc41da85ed80cb5d5f5f3aa890e72bac1b407ae/overlays/default.nix#L22
        libsForQt5 = prev.libsForQt5.overrideScope (
          qt5final: qt5prev: {
            fcitx5-with-addons = qt5prev.fcitx5-with-addons.override { withConfigtool = false; };
          }
        );
      })
    ];

    fonts = {
      packages = with pkgs; [
        noto-fonts
        noto-fonts-extra
        noto-fonts-cjk-serif
        noto-fonts-cjk-sans
        noto-fonts-emoji
      ];
      fontDir.enable = true;
      fontconfig = {
        enable = true;
        defaultFonts = {
          serif = [ "Noto Serif CJK JP" "Noto Color Emoji" ];
          sansSerif = [ "Noto Sans CJK JP" "Noto Sans" "Noto Color Emoji" ];
          monospace = [ "Noto Sans Mono" "Noto Color Emoji" ];
          emoji = [ "Noto Color Emoji" ];
        };
      };
    };

    services.xserver.xkb = {
      model = config.console.keyMap;
      layout = "jp"; # keyboard layout: https://nixos.wiki/wiki/Keyboard_Layout_Customization
      options = "ctrl:nocaps";
    };
  };
}
