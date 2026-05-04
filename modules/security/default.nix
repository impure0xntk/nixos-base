{
  config,
  pkgs,
  lib,
  ...
}:
let
  isHeadless = config.my.system.core.headless or false;
in
{
  imports = [
    ./STIG.nix
    ./clamav
  ];
  assertions = [
    {
      assertion = !config.security.sudo.enable;
      message = "Use sudo-rs instead of sudo, and set nothing to security.sudo";
    }
  ];
  # NixOS -25.11 official hardened profile
  boot.kernelPackages = lib.mkDefault pkgs.linuxKernel.packages.linux_hardened;
  nix.settings.allowed-users = lib.mkDefault [ "@users" ];
  environment.memoryAllocator.provider = lib.mkDefault "scudo";
  environment.variables.SCUDO_OPTIONS = lib.mkDefault "zero_contents=true";
  security.lockKernelModules = lib.mkDefault true;
  security.protectKernelImage = lib.mkDefault true;
  security.allowSimultaneousMultithreading = lib.mkDefault false;
  security.forcePageTableIsolation = lib.mkDefault true;
  # This is required by podman to run containers in rootless mode.
  security.unprivilegedUsernsClone = lib.mkDefault config.virtualisation.containers.enable;
  security.virtualisation.flushL1DataCache = lib.mkDefault "always";
  security.apparmor.enable = lib.mkDefault true;
  security.apparmor.killUnconfinedConfinables = lib.mkDefault true;

  # Replace sudo to sudo-rs, and only allow wheel group
  security.sudo.enable = false;
  security.sudo-rs = {
    enable = true;
    execWheelOnly = true;
  };

  # Disable coredump
  systemd.coredump.enable = lib.mkDefault false;
  security.pam.loginLimits = lib.optionals (!config.systemd.coredump.enable) [
    {
      domain = "*";
      item = "core";
      type = "soft";
      value = "0";
    }
  ];

  # Nix build sandbox hardening
  # Source: https://nixos.org/manual/nix/stable/command-ref/conf-file.html
  # CVE-2018-1000156 (arbitrary code execution via build phase)
  nix.settings.sandbox = true;

  # Kernel hardening
  boot.kernelParams = [
    # Vulnerability mitigations (Spectre v1/v2, Meltdown, L1TF, MDS, TAA, etc.)
    # CVE-2017-5753, CVE-2017-5715, CVE-2017-5754, CVE-2018-3639, CVE-2018-3615
    # CVE-2018-12126/12127/12130, CVE-2019-11091, CVE-2019-11135
    # CVE-2025-40300 (VMSCAPE - Intel VT-x escapes, IBPB covered by auto)
    # Source: https://kernel.org/doc/html/latest/admin-guide/hw-vuln/index.html
    "mitigations=auto"

    # IOMMU for DMA attack prevention (Thunderspy, Thunderbolt attacks)
    # CVE-2019-14615, CVE-2020-12268, CVE-2020-12269
    # Source: https://privsec.dev/posts/linux/desktop-linux-hardening/
    "intel_iommu=on"
    "amd_iommu=force_isolation"
    "iommu=force"

    # Kernel heap hardening: disable slab merging to prevent heap metadata attacks
    # Source: https://www.kernel.org/doc/html/latest/vm/slub.html
    "slab_nomerge"

    # Memory initialization to mitigate use-after-free (UAF) exploits
    # CVE-2017-1000405, CVE-2018-17972
    # Source: https://www.kernel.org/doc/html/latest/core-api/memory-allocation.html
    "init_on_alloc=1"
    "init_on_free=1"

    # Page allocator randomization to complicate heap spraying
    # Source: https://www.kernel.org/doc/html/latest/admin-guide/sysctl/vm.html
    "page_alloc.shuffle=1"

    # Kernel Page Table Isolation (mitigates Meltdown and related attacks)
    # CVE-2017-5754
    # Source: https://www.kernel.org/doc/html/latest/x86/pti.html
    "pti=on"

    # Randomize kernel stack offset for each syscall (KASLR improvement)
    # Source: https://www.kernel.org/doc/html/latest/admin-guide/kernel-parameters.html
    "randomize_kstack_offset=on"

    # Disable vsyscall interface (deprecated, allows LPE via CVE-2016-9604)
    # Source: https://nixos.wiki/wiki/Security
    "vsyscall=none"

    # Disable debugfs to prevent information leaks
    # Source: https://privsec.dev/posts/linux/desktop-linux-hardening/
    "debugfs=off"

    # Module signing
    # https://wiki.archlinux.org/title/Security
    "module.sig_enforce=1"

    # "l1tf=full,force" # For container host
    "oops=panic"
    "lockdown=confidentiality"

    # kCFI (Kernel Control Flow Integrity)
    # Source: https://docs.kernel.org/next/x86/shstk.html
    "cfi=kcfi"

    # Disable early PCI DMA (busmaster bit protection)
    # Prevents DMA attacks during early boot
    # Source: https://en.wikipedia.org/wiki/Bus_mastering
    "efi=disable_early_pci_dma"
  ]
  ++ (lib.optionals isHeadless [
    # Disable unprivileged user namespaces (reduces kernel attack surface)
    # Many CVEs require user namespaces: CVE-2022-0492, CVE-2022-25636, CVE-2022-0185
    # WARNING: Breaks browser sandboxing, Flatpak, Podman rootless
    # Source: https://privsec.dev/posts/linux/desktop-linux-hardening/
    "user.max_user_namespaces=0"
  ]);
  boot.kernel.sysctl = lib.my.flatten "_flattenIgnore" {
    kernel = {
      # Restrict dmesg access (contains kernel pointer info)
      # CVE-2017-1000405
      # Source: https://wiki.archlinux.org/title/Sysctl
      dmesg_restrict = 1;

      # Restrict kernel pointer exposure via /proc/kallsyms
      # Source: https://www.kernel.org/doc/html/latest/admin-guide/sysctl/kernel.html
      kptr_restrict = 2;

      # Restrict perf events (side-channel attacks via perf)
      # CVE-2013-2094
      # Source: https://nixos.wiki/wiki/Security
      perf_event_paranoid = 3;

      # Disable unprivileged BPF to prevent BPF-based exploits
      # CVE-2020-8835, CVE-2021-3490, CVE-2022-23222, CVE-2023-2163, CVE-2025-37884
      # Source: https://privsec.dev/posts/linux/desktop-linux-hardening/
      unprivileged_bpf_disabled = 1;

      # Maximize ASLR (Address Space Layout Randomization) entropy
      # Source: https://wiki.archlinux.org/title/Sysctl
      randomize_va_space = 2;

      # Disable core dumps to prevent credential/sensitive data leaks
      # Source: https://privsec.dev/posts/linux/desktop-linux-hardening/
      core_pattern = "/dev/null";

      # YAMA ptrace scope: 3 = no process can use ptrace (strongest)
      # Prevents process injection, debugging abuse
      # Source: https://www.kernel.org/doc/html/latest/admin-guide/LSM/Yama.html
      yama.ptrace_scope = 3;

      # Disable kexec to prevent unsigned kernel loading
      # Source: https://nixos.wiki/wiki/Security
      kexec_load_disabled = 1;

      # Restrict printk (kernel log) access
      # Source: https://privsec.dev/posts/linux/desktop-linux-hardening/
      printk = "3 3 3 3";

      # Disable SysRq (Magic SysRq keys) to prevent forced reboots, etc.
      # Source: https://wiki.archlinux.org/title/Sysctl
      sysrq = 0;

      # Disable unprivileged user namespace cloning (alternative to boot param)
      # Source: https://privsec.dev/posts/linux/desktop-linux-hardening/
      unprivileged_userns_clone = 0;

      # Disable kernel ptrace access to prevent debugging abuse
      # Source: Lynis
      ctrl-alt-del = 0;
    };

    vm = {
      mmap_rnd_bits = 32;
      mmap_rnd_compat_bits = 16;
    };

    fs = {
      # https://www.tenable.com/audits/items/CIS_Ubuntu_14.04_LTS_Server_v2.1.0_L1.audit:db54813513bcf4eb7d16e7b5b978bb70
      suid_dumpable = 0;

      # Protected regular files (prevent O_CREAT | O_EXCL race conditions)
      # CVE-2022-0185
      # Source: https://wiki.archlinux.org/title/Sysctl
      protected_regular = 2;

      # Protected FIFOs (prevent O_CREAT | O_EXCL race conditions)
      # CVE-2022-0185
      # Source: https://wiki.archlinux.org/title/Sysctl
      protected_fifos = 2;

      # Protected hardlinks (prevent TOCTOU attacks via hardlinks)
      # Source: https://privsec.dev/posts/linux/desktop-linux-hardening/
      protected_hardlinks = 1;

      # Protected symlinks (prevent TOCTOU attacks via symlinks)
      # Source: https://privsec.dev/posts/linux/desktop-linux-hardening/
      protected_symlinks = 1;
    };

    net = {
      # Harden BPF JIT compiler (if unprivileged BPF disabled)
      # Source: https://www.kernel.org/doc/html/latest/admin-guide/sysctl/net.html
      core.bpf_jit_harden = 2;

      ipv4 = {
        # Enable TCP SYN cookies (prevents SYN flood attacks)
        # CVE-2016-5696
        # Source: https://wiki.archlinux.org/title/Sysctl
        tcp_syncookies = 1;

        # Enable RFC 1337 (TIME_WAIT assassination protection)
        # Source: https://www.rfc-editor.org/rfc/rfc1337
        tcp_rfc1337 = 1;

        # Ignore ICMP echo broadcasts
        icmp_echo_ignore_broadcasts = 1;

        # Ignore bogus ICMP error responses
        icmp_ignore_bogus_error_responses = 1;

        conf = {
          all = {
            # Reverse path filtering (anti-spoofing)
            # Source: https://wiki.archlinux.org/title/Sysctl
            rp_filter = 1;

            # Disable IP forwarding (unless acting as router)
            forwarding = 0;

            # Disable ICMP redirect acceptance (prevents MITM via redirects)
            # CVE-2014-4608
            # Source: https://nixos.wiki/wiki/Security
            accept_redirects = 0;
            send_redirects = 0;

            # Disable source routing (prevents routing attacks)
            # CVE-2019-14899 (source route + PMTU manipulation in VPN tunnels)
            # Source: https://privsec.dev/posts/linux/desktop-linux-hardening/
            accept_source_route = 0;

            # Disable multicast forwarding (if not used)
            mc_forwarding = 0;

            # ARP hardening: ignore requests not for local addresses
            # Source: https://privsec.dev/posts/linux/desktop-linux-hardening/
            arp_ignore = 2;

            # ARP hardening: announce only if address configured
            arp_announce = 2;

            # ARP hardening: drop gratuitous ARP to prevent ARP poisoning
            # Source: https://privsec.dev/posts/linux/desktop-linux-hardening/
            drop_gratuitous_arp = 1;

            # ARP hardening: filter ARP to prevent cache poisoning
            # Source: https://privsec.dev/posts/linux/desktop-linux-hardening/
            arp_filter = 1;
          };
          default = {
            rp_filter = 1;
            forwarding = 0;
            accept_redirects = 0;
            send_redirects = 0;
            accept_source_route = 0;

            # ARP hardening: drop gratuitous ARP
            drop_gratuitous_arp = 1;

            # ARP hardening: filter ARP
            arp_filter = 1;
          };
        };
      };
    };

    ipv6 = {
      conf = {
        all = {
          # Disable IPv6 if not used (reduces attack surface significantly)
          # Source: https://privsec.dev/posts/linux/desktop-linux-hardening/
          disable_ipv6 = 1;

          # Disable IPv6 redirects
          accept_redirects = 0;
          forwarding = 0;

          # Disable IPv6 source routing
          accept_source_route = 0;

          # Disable IPv6 router advertisements
          accept_ra = 0;
        };
        default = {
          accept_redirects = 0;
          forwarding = 0;
        };
      };
    };
  };

  boot.blacklistedKernelModules = [
    # FireWire (DMA attacks via physical access)
    # CVE-2010-4347
    "firewire-core"
    "firewire-ohci"
    "firewire-sbp2"

    # USB/IP (unprivileged user escape via USB/IP)
    # CVE-2022-30594
    "usbip-core"

    # Crypto API sockets (Copy Fail vulnerability - CVE-2026-31431)
    # Disclosed 2026-04-29. AF_ALG crypto socket interface logic bug.
    "algif_aead"
    "algif_skcipher"
    "algif_rng"
    "algif_hash"

    # Deprecated/vulnerable filesystems
    "cramfs" # Deprecated, vulnerable FS
    "freevxfs" # Deprecated FS
    "jffs2" # Vulnerable embedded FS
    "hfs" # Vulnerable Apple FS (multiple CVEs)
    "hfsplus" # Vulnerable Apple FS
    "squashfs" # If not needed
    "udf" # If not needed

    # Legacy network protocols (reduce attack surface)
    "ax25"
    "netrom"
    "rose"
    "decnet"
    "econet"
    "x25"
    "ipx"
    "appletalk"
    "net-pf-31" # Appletalk
    "af_802154" # IEEE 802.15.4

    # Kernel SMB server (multiple CVEs like CVE-2023-384xx)
    "ksmbd"

    # nftables (if using iptables instead)
    "nftables" # If not needed

    # Bluetooth (if not used)
    "bluetooth"

    # Thunderbolt (if not used, CVE-2019-14615)
    "thunderbolt"
  ];

  # /proc hardening
  # Source: https://nixos.wiki/wiki/Security
  boot.specialFileSystems."/proc" = lib.mkIf isHeadless {
    options = [
      "nosuid"
      "nodev"
      "noexec"
      "hidepid=2"
    ];
  };

  # systemd service hardening
  # Source: https://www.freedesktop.org/software/systemd/man/systemd.service.html
  systemd.oomd.settings.OOM = {
    ProcSubset = "pid"; # Restrict /proc access for system services
  };

}
