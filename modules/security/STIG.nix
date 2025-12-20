# Ref: https://ncp.nist.gov/checklist/1260
# Use STIG viewer to show checklist.
#
# NOTE: audit/auditd does not work on WSL becaulse "ConditionVirtualization" in systemd service file.
{ config, pkgs, lib, ... }:
let
  useAudit = !(config.my.system.platform.type == "wsl"
    || config.my.system.platform.type == "nspawn");
  useSshd = config.services.openssh.enable;
  # For V-268082, V-268083
  # Based on US Government Standard Mandatory DOD Notice and Consent.
  interactiveLoginNotice = ''
    You are accessing a secured information system that is provided for authorized use only.
    By using this system (including any device connected to it), you acknowledge and consent to the following conditions:

    - This system is monitored for security and compliance purposes.
    - Any data stored, transmitted, or processed on this system may be accessed and reviewed by authorized personnel.
    - Unauthorized use of this system is strictly prohibited and may result in disciplinary action and/or legal consequences.
    - By continuing to use this system, you agree to comply with all applicable policies and security guidelines."
    '';
in
{
  config = {
    # V-268078 (firewall) defines at networks
    # V-268079: skip.

    # V-268080
    security.auditd.enable = lib.mkDefault useAudit;
    security.audit.enable = lib.mkDefault useAudit;

    # V-268081, V-268170
    security.pam.services =
    let
      passwordRequisite = ''
        password requisite ${pkgs.libpwquality.lib}/lib/security/pam_pwquality.so
      '';
      pamfile = passwordRequisite + ''
        auth required pam_faillock.so preauth silent audit deny=3 fail_interval=900 unlock_time=0
        auth sufficient pam_unix.so nullok try_first_pass
        auth [default=die] pam_faillock.so authfail audit deny=3 fail_interval=900 unlock_time=0
        auth sufficient pam_faillock.so authsucc

        account required pam_faillock.so
      '';
    in {
      login.text = pkgs.lib.mkDefault pamfile;
      sshd.text = pkgs.lib.mkDefault pamfile;
      sudo.text = pkgs.lib.mkDefault passwordRequisite;
    };

    # V-268082
    services.getty.helpLine = interactiveLoginNotice;
    # V-268083
    services.openssh.banner = interactiveLoginNotice;
    # V-268084
    services.displayManager.gdm.banner = interactiveLoginNotice;

    # V-268085
    security.pam.loginLimits = [
      {
        domain = "*";
        item = "maxlogins";
        type = "hard";
        value = "10";
      }
    ];

    # V-268086: (automatic display session lock) skip for experience
    # V-268087: (vlock) skip for experience

    # V-268088
    services.openssh.settings.LogLevel = "VERBOSE";

    # V-268089
    services.openssh.settings.Ciphers = [
      "aes256-ctr"
      "aes192-ctr"
      "aes128-ctr"
    ];

    # V-268090: (audit) skip because V-268080 satisfies this.

    security.audit.rules =
      let
        # https://github.com/ansible-lockdown/UBUNTU22-CIS/pull/273/files
        commandForV268095 = if pkgs.stdenv.hostPlatform.isAarch
          then "renameat,unlinkat"
          else "rename,unlink,rmdir,renameat,unlinkat";
        commandForV268098 = if pkgs.stdenv.hostPlatform.isAarch
          then "truncate,ftruncate,openat,open_by_handle_at"
          else "open,creat,truncate,ftruncate,openat,open_by_handle_at";
        commandForV268099 = if pkgs.stdenv.hostPlatform.isAarch
          then "fchown,fchownat"
          else "chown,fchown,lchown,fchownat";
        commandForV268100 = if pkgs.stdenv.hostPlatform.isAarch
          then "fchmod,fchmodat"
          else "chmod,fchmod,fchmodat";
      in [
      # V-268091, V-268148
      "-a always,exit -F arch=b64 -S execve -C uid!=euid -F euid=0 -k execpriv"
      "-a always,exit -F arch=b32 -S execve -C uid!=euid -F euid=0 -k execpriv"
      "-a always,exit -F arch=b32 -S execve -C gid!=egid -F egid=0 -k execpriv "
      "-a always,exit -F arch=b64 -S execve -C gid!=egid -F egid=0 -k execpriv "

      # V-268094
      "-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=unset -k privileged-mount"
      "-a always,exit -F arch=b64 -S mount -F auid>=1000 -F auid!=unset -k privileged-mount"

      # V-268095
      "-a always,exit -F arch=b32 -S ${commandForV268095} -F auid>=1000 -F auid!=unset -k delete"
      "-a always,exit -F arch=b64 -S ${commandForV268095} -F auid>=1000 -F auid!=unset -k delete"

      # V-268096
      "-a always,exit -F arch=b32 -S init_module,finit_module,delete_module -F auid>=1000 -F auid!=unset -k module_chng"
      "-a always,exit -F arch=b64 -S init_module,finit_module,delete_module -F auid>=1000 -F auid!=unset -k module_chng"

      # V-268097 is defined at the bottom.

      # V-268098
      "-a always,exit -F arch=b32 -S ${commandForV268098} -F exit=-EACCES -F auid>=1000 -F auid!=unset -F key=access"
      "-a always,exit -F arch=b32 -S ${commandForV268098} -F exit=-EPERM -F auid>=1000 -F auid!=unset -F key=access"
      "-a always,exit -F arch=b64 -S ${commandForV268098} -F exit=-EACCES -F auid>=1000 -F auid!=unset -F key=access"
      "-a always,exit -F arch=b64 -S ${commandForV268098} -F exit=-EPERM -F auid>=1000 -F auid!=unset -F key=access"

      # V-268099
      "-a always,exit -F arch=b32 -S ${commandForV268099} -F auid>=1000 -F auid!=unset -F key=perm_mod"
      "-a always,exit -F arch=b64 -S ${commandForV268099} -F auid>=1000 -F auid!=unset -F key=perm_mod"

      # V-268100
      "-a always,exit -F arch=b32 -S ${commandForV268100} -F auid>=1000 -F auid!=unset -k perm_mod"
      "-a always,exit -F arch=b64 -S ${commandForV268100} -F auid>=1000 -F auid!=unset -k perm_mod"

      # V-268119
      "--loginuid-immutable"

      # V-268163
      "-a always,exit -F arch=b32 -S setxattr,fsetxattr,lsetxattr,removexattr,fremovexattr,lremovexattr -F auid>=1000 -F auid!=-1 -k perm_mod"
      "-a always,exit -F arch=b32 -S setxattr,fsetxattr,lsetxattr,removexattr,fremovexattr,lremovexattr -F auid=0 -k perm_mod"
      "-a always,exit -F arch=b64 -S setxattr,fsetxattr,lsetxattr,removexattr,fremovexattr,lremovexattr -F auid>=1000 -F auid!=-1 -k perm_mod"
      "-a always,exit -F arch=b64 -S setxattr,fsetxattr,lsetxattr,removexattr,fremovexattr,lremovexattr -F auid=0 -k perm_mod"

      # V-268164
      "-a always,exit -F path=/run/current-system/sw/bin/usermod -F perm=x -F auid>=1000 -F auid!=unset -k privileged-usermod"

      # V-268165
      "-a always,exit -F path=/run/current-system/sw/bin/chage -F perm=x -F auid>=1000 -F auid!=unset -k privileged-chage"
      "-a always,exit -F path=/run/current-system/sw/bin/chcon -F perm=x -F auid>=1000 -F auid!=unset -k perm_mod"

      # V-268166
      "-w /var/log/lastlog -p wa -k logins"

      # V-268167
      "-w /etc/sudoers -p wa -k identity"
      "-w /etc/passwd -p wa -k identity"
      "-w /etc/shadow -p wa -k identity"
      "-w /etc/gshadow -p wa -k identity"
      "-w /etc/group -p wa -k identity"
      "-w /etc/security/opasswd -p wa -k identity"
    ] ++ lib.optionals config.services.cron.enable [
      # V-268097
      "-w /var/cron/tabs/ -p wa -k services"
      "-w /var/cron/cron.allow -p wa -k services"
      "-w /var/cron/cron.deny -p wa -k services"
    ];

    boot.kernelParams = [
      "audit=1" # V-268092
      "audit_backlog_limit=8192" # V-268093
      "fips=1" # V-268168
    ];

    # V-268{094,095,096,097,098,099,100}: is the above audit.rules

    # V-26810{1,2,3,4,5,6}, V-268110
    environment.etc."audit/auditd.conf".text = ''
      space_left_action = syslog
      admin_space_left_action = syslog
      space_left = 25%
      admin_space_left = 10%
      disk_full_action = HALT
      disk_error_action = HALT
      log_group = root
    '';

    # V-268107
    services.syslog-ng.enable = useAudit;
    # V-2681{08,09}: (transfer audit log) does not define here. Here is for mother system only.
    # V-26811{1,2,3,4}: (audit directory owner/permission): skip. default path /var/log/audit, and default owner is root

    # V-26811{5,6,7,8}
    services.syslog-ng.extraConfig = ''
      options {
        owner(root);
        dir_owner(root);
        group(root);
        dir_group(root);
        dir_perm(0750);
        perm(0640);
      };
    '';

    # V-268119: is the above audit.rules

    # V-26812{0,1}: (nixos configuration owner/perm) skip

    # V-268124: (PKI-based auth) skip because does not use ldap and others

    # V-268125: (each ssh-keygen) skip

    # V-26812{6,7,8,9}, V-268134, V-268145, V-268169:
    environment.etc."/security/pwquality.conf".text = ''
      ucredit=-1
      lcredit=-1
      dcredit=-1
      difok=8
      minlen=15
      ocredit=-1
      dictcheck=1
    '';

    # V-26813{0,2,3}, V-268171, V-268181
    environment.etc."login.defs".text = pkgs.lib.mkForce ''
      ENCRYPT_METHOD SHA256
      PASS_MIN_DAYS 1
      PASS_MAX_DAYS 60
      FAIL_DELAY 4

      DEFAULT_HOME yes

      SYS_UID_MIN  400
      SYS_UID_MAX  999
      UID_MIN      1000
      UID_MAX      29999

      SYS_GID_MIN  400
      SYS_GID_MAX  999
      GID_MIN      1000
      GID_MAX      29999

      TTYGROUP     tty
      TTYPERM      0620

      # Ensure privacy for newly created home directories.
      UMASK        077

      # Uncomment this and install chfn SUID to allow nonroot
      # users to change their account GECOS information.
      # This should be made configurable.
      #CHFN_RESTRICT frwh
    '';

    # V-268131: (no telnet) skip

    # V-26813{2,3}: is the above login.defs
    # V-268134: is the above pwquality

    # V-268135: (user management): skip

    environment.systemPackages = [
      pkgs.opencryptoki # V-268136,
      # pkgs.aide # a part of V-268153
    ];

    # V-268137
    services.openssh.settings.PermitRootLogin = "no";

    # V-268138
    users.mutableUsers = false;

    # V-268139: (usb-guard) skip
    # V-268140: (root directory perm) skip

    # V-268141
    boot.kernel.sysctl."net.ipv4.tcp_syncookies" = 1;

    # V-26814{2,3}: (ssh client alive interval): skip
    # V-268144: (LUKS-Encrypted File Systems): skip
    # V-268145: is the above pwquality

    # V-268146
    networking.wireless.enable = false;
    # V-268147
    hardware.bluetooth.enable = false;

    # V-268148: is the above audit

    # V-268149: (timeserver) skip
    # V-268150
    services.timesyncd.extraConfig = ''
      PollIntervalMaxSec=60
    '';
    # V-268151
    services.timesyncd.enable = true;

    # V-268152
    # nix.settings.allowed-users = [ "root" "@wheel" ];

    # V-268153. install aide at the above environment.systemPackages, but skip
    # nixpkgs.overlays = [
    #   (final: prev: {
    #     aide = prev.aide.overrideAttrs (old: {
    #       configureFlags = (old.configureFlags or [ ]) ++ [ "--sysconfdir=/etc" ];
    #      });
    #   })
    # ];
    # environment.etc = {
    #   "aide.conf" = { # Creates /etc/aide.conf
    #      text = '''';
    #      mode = "0444";
    #    };
    # };
    # systemd.timers.aide = {
    #   enable = true;
    #   timerConfig = {
    #     OnCalendar = "daily";
    #     Unit = "aide.service";
    #   };
    #   wantedBy = ["timers.target"];
    # };
    # systemd.services.aide = {
    #   enable = true;
    #   serviceConfig.Type = "oneshot";
    #   path = [ pkgs.aide ];
    #   script = ''
    #     if test -f /etc/aide.db; then
    #       aide --update
    #     else
    #       aide -i
    #     fi
    #     mv /etc/aide.db{.new,}
    #
    #     aide -c /etc/aide.conf --check
    #   '';
    # };

    # V-268154
    nix.settings.require-sigs = true;

    # V-268155: (sudo password timeout) skip
    # V-268156: (wheel needs password) skip

    # V-268157
    services.openssh.settings.Macs = [
      "hmac-sha2-512"
      "hmac-sha2-256"
    ];

    # V-268158: (rate limit for DDoS protection) skip
    # V-268159: (sshd enable) skip

    boot.kernel.sysctl = {
      # V-268160
      "kernel.kptr_restrict" = 1;
      # V-268161
      "kernel.randomize_va_space" = 2;
    };

    # V-268162: (nixos remove old packages after upgrade) skip
    # V-26816{3,4,5,6,7}: is the above audit.rules
    # V-268168: is the above kernelParams
    # V-268169: is the above pwquality
    # V-268170: is the above pam
    # V-268171: is the above login.defs
    # V-268172: (disable display session auto login) skip

    # V-268173
    security.apparmor.enable = true;

    # V-268174
    environment.etc."/default/useradd".text = pkgs.lib.mkForce
    ''
      INACTIVE=35
    '';

    # V-268175: (SHA-512 passwd) skip

    # V-268176
    services.openssh.settings.UsePAM = useSshd;

    # V-268177 defines pkcs11, but not used. Skip
    # security.pam.p11.enable = true;

    # V-268178
    services.sssd.config = ''
      [pam]
      offline_credentials_expiration = 1
    '';

    # V-268179 defines pkcs11, but not used. Skip
    # environment.etc."pam_pkcs11/pam_pkcs11.conf".text = ''
    #   cert_policy = ca,signature,ocsp_on, crl_auto;
    # '';

    # V-268180: (update nixos) skip
    # V-268181: (login.defs basics) is the above login.defs
  };
}
