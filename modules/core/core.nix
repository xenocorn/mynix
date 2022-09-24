{ config, pkgs, lib, ... }:

let
  constants = import /etc/nixos/nixos_host_config/constants.nix;
in
{
  imports = [
    ./scripts.nix
    ../../channels/hm/a8d00f5c038cf7ec54e7dac9c57b171c1217f008/chnl/nixos
  ];

  security.allowSimultaneousMultithreading = true;
  security.allowUserNamespaces = true;
  security.lockKernelModules = false;
  security.protectKernelImage = true; # Prevent replacing the running kernel image
  security.forcePageTableIsolation = true;
  security.virtualisation.flushL1DataCache = "always"; # Reduce performance!

  boot = {
    cleanTmpDir = true;
    consoleLogLevel = 0; # show all log
    tmpOnTmpfs = true;
    kernelParams = [
      "lockdown=confidentiality"
      "page_poison=1"
      "page_alloc.shuffle=1"
      "nohibernate"
    ];
    kernel.sysctl = {
      "max_user_watches" = 524288;
      "kernel.dmesg_restrict" = true;
      "kernel.unprivileged_bpf_disabled" = true;
      "kernel.unprivileged_userns_clone" = false;
      "kernel.kexec_load_disabled" = true;
      "kernel.sysrq" = 4;
      "net.core.bpf_jit_harden" = true;
      "vm.swappiness" = 1;
      "vm.unprivileged_userfaultfd" = false;
      "dev.tty.ldisc_autoload" = false;
      "kernel.yama.ptrace_scope" = lib.mkOverride 500 1; # Allow ptrace only for parent->child proc
      "kernel.kptr_restrict" = lib.mkOverride 500 2; # Hide kptrs even for processes with CAP_SYSLOG
      "net.core.bpf_jit_enable" = false; # Disable ebpf jit
      "kernel.ftrace_enabled" = false; # Disable debugging via ftrace
      "net.ipv4.icmp_echo_ignore_broadcasts" = true; # Ignore broadcast ICMP
      # Strict reverse path filtering
      "net.ipv4.conf.all.log_martians" = true;
      "net.ipv4.conf.all.rp_filter" = true;
      "net.ipv4.conf.default.log_martians" = true;
      "net.ipv4.conf.default.rp_filter" = true;
      # Ignore incoming ICMP redirects
      "net.ipv4.conf.all.accept_redirects" = false;
      "net.ipv4.conf.all.secure_redirects" = false;
      "net.ipv4.conf.default.accept_redirects" = false;
      "net.ipv4.conf.default.secure_redirects" = false;
      "net.ipv6.conf.all.accept_redirects" = false;
      "net.ipv6.conf.default.accept_redirects" = false;
      # Ignore outgoing ICMP redirects
      "net.ipv4.conf.all.send_redirects" = false;
      "net.ipv4.conf.default.send_redirects" = false;
    };
    kernelModules  = [ "fuse" ]; # Regular
    initrd.kernelModules = []; # Early loaded
    blacklistedKernelModules = [];
  };

  fileSystems = {
    "/".options = [ "noatime" "nodiratime" ]; # Add "discard" ?
    "/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "noatime" "noexec" "nosuid" "nodev" "mode=1777" ];
    };
  };

  system.autoUpgrade.enable = false;

  # TODO Move to separeted module
  #sound.enable = true;
  #hardware.pulseaudio = {
  #  enable = true;
  #  package = pkgs.pulseaudioFull;
  #  support32Bit = true;
  #  extraModules = [ pkgs.pulseaudio-modules-bt ];
  #  daemon.config = {
  #    nice-level = -15;
  #    realtime-scheduling = "yes";
  #  };
  #};

  users = {
    mutableUsers = false;
    users.admin = {
      isNormalUser = true;
      extraGroups = [ 
        "wheel"
        "audio"
        "sound"
        "video"
        "input"
        "tty"
        "power"
        "games"
        "scanner"
        "storage"
        "optical"
        "networkmanager"
        "vboxusers"
      ];
      home = "/home/admin";
      createHome = true;
      useDefaultShell = true;
    };
    users.root.hashedPassword = null;
  };

  # Enable nix store optimisation
  nix = {
    autoOptimiseStore = true;
    binaryCaches = lib.mkForce [ "https://cache.nixos.org" ];
    #narinfoCacheNegativeTtl = 0;
    #narinfoCachePositiveTtl = 0;
    #gc = {
    #  automatic = true;
    #  dates = "weekly";
    #  options = "--delete-older-than 7d";
    #};
  };

  nixpkgs.config.allowUnfree = true;

  # Enable zram swap
  zramSwap = {
    enable = true;
    priority = 1000;
    algorithm = "zstd";
    numDevices = 1;
    swapDevices = 1;
    memoryPercent = 50;
  };

  # Enable KSM
  hardware.ksm.enable = true;

  hardware.enableRedistributableFirmware = true;

  services.fstrim = {
    enable = true;
    interval = "dayly";
  };

  # Doc
  documentation.dev.enable = true;
  documentation.doc.enable = true;
  documentation.info.enable = true;
  documentation.man.enable = true;  

  powerManagement = {
    enable = (lib.mkForce true);
    powertop.enable = true;
    cpuFreqGovernor = lib.mkDefault "powersave"; # or performance
    resumeCommands = ''
      ${pkgs.autorandr}/bin/autorandr -c
    '';
  };

  services.upower.enable = true;

  # Disable sleep/hibernate/suspend
  services.logind.lidSwitch = lib.mkForce "ignore";
  systemd.targets.sleep.enable = lib.mkForce false;
  systemd.targets.suspend.enable = lib.mkForce false;
  systemd.targets.hibernate.enable = lib.mkForce false;
  systemd.targets.hybrid-sleep.enable = lib.mkForce false;

  networking = {
    #proxy.default = constants.Promux1Socks;
    usePredictableInterfaceNames = true;
    #useDHCP = true;
    enableIPv6 = true;
    dhcpcd.enable = true;
    dhcpcd.extraConfig = "\nnoipv6rs \nnoipv6";
    useHostResolvConf = false;
    #tcpcrypt.enable = true;
    networkmanager = {
      enable = true;
      dhcp = "dhcpcd";
      wifi = {
        macAddress = "random";
        scanRandMacAddress = true;
      };
      # dispatcherScripts  # https://github.com/cyplo/dotfiles/blob/master/nixos/common-hardware.nix
    };
    extraHosts = "";
    firewall = {
      enable = true;
      allowedTCPPorts = lib.mkForce [];
      allowedUDPPorts = lib.mkForce [];
      trustedInterfaces = lib.mkForce [ "lo" ]; #open all ports on localhost
      #extraCommands = "ip6tables -A INPUT -s fe80::/10 -j ACCEPT";
    };
  };

  environment.shellAliases = {
    # Abbreviations
    e = "exit";
    rf = "rm -rf";
    ll = " exa --oneline -L 1 -T -F --group-directories-first -l";
    la = "exa --oneline -L 1 -T -F --group-directories-first -la";
    ls = "exa --oneline -L 1 -T -F --group-directories-first";
    c = "clear";
    h = "history | rg";
    ch = "cd ~";
    # Nixos
    # TODO chaige notify-desktop to some universal variant for both x11 && wayland
    nswitch = "sudo exectime nixos-rebuild switch && notify-desktop --urgency=critical Switched &> /dev/null";
    ncswitch = "sudo exectime nixos-rebuild switch --option extra-substituters https://cache.nixos.org && notify-desktop --urgency=critical Switched &> /dev/null";
    ncollect = "sudo exectime nix-collect-garbage -d && notify-desktop --urgency=critical 'Garbage collected' &> /dev/null";
    noptimise = "sudo exectime nix-store --optimise && notify-desktop --urgency=critical 'Store optimised' &> /dev/null";
    npull = "sudo withdir /etc/nixos/mynix exectime git pull";
    # Etc
    qr = "qrencode -t UTF8 -o -";
    stop = "shutdown now";
    print = "figlet -c -t";
    # TODO chaige xclip to some universal variant for both x11 && wayland
    copy = "xclip -selection c";
    genpass = "openssl rand 33 | base64";
    cppass = "openssl rand 33 | base64 | xclip -selection c";
    pause = "sleep 100000d";
    gtree = "exa --oneline -T -F --group-directories-first -a --git-ignore --ignore-glob .git";
    tree = "exa --oneline -T -F --group-directories-first -a";
    cat = "bat";
    sysstat = "systemctl status";
    journal = "journalctl -u";
    size = "du -shP";
    shell-nix = "nix-shell --run fish";
    root = "sudo -i";
    play = "ansible-playbook";
    dropproxy = ''export ALL_PROXY="" && export all_proxy="" && export SOCKS_PROXY="" && export socks_proxy="" && export HTTP_PROXY="" && export http_proxy="" && export HTTPS_PROXY="" && export https_proxy=""'';
  };
  
  programs.fish ={
    enable = true;
    #plugins = [{
    #    name = "z";
    #    src = pkgs.fetchFromGitHub {
    #      owner = "jethrokuan";
    #      repo = "z";
    #      rev = "e0e1b9dfdba362f8ab1ae8c1afc7ccf62b89f7eb";
    #      sha256 = "0dbnir6jbwjpjalz14snzd3cgdysgcs3raznsijd6savad3qhijc";
    #    };
    #}];
  };
  
  users.extraUsers.admin.shell = pkgs.fish;
  users.extraUsers.root.shell = pkgs.fish;

  i18n.defaultLocale = lib.mkForce "en_US.utf8";
 
  i18n.extraLocaleSettings = lib.mkForce {
    LC_ADDRESS = "en_US.utf8";
    LC_IDENTIFICATION = "en_US.utf8";
    LC_MEASUREMENT = "en_US.utf8";
    LC_MONETARY = "en_US.utf8";
    LC_NAME = "en_US.utf8";
    LC_NUMERIC = "en_US.utf8";
    LC_PAPER = "en_US.utf8";
    LC_TELEPHONE = "en_US.utf8";
    LC_TIME = "en_US.utf8";
  };

  services.ratbagd.enable = true; # daemon to configure input devices

  services.tlp = {
    enable = true;
    settings = {
      "DISK_IOSCHED" = "mq-deadline";
    };
  };

  #services.pcscd.enable = true;
  programs.gnupg.agent = {
     enable = true;
     pinentryFlavor = "curses";
     #enableSSHSupport = true;
  };

  virtualisation = {
    docker.enable = false;
    podman = {
      enable = true;
      dockerCompat = true;
    };
  };

  environment.systemPackages = with pkgs; [
    # Basic
    lsof
    git
    wget
    bottom #btm
    htop
    iftop
    sysstat
    btop
    openssh
    sshpass
    ripgrep #rg
    links2
    inetutils
    killall
    xclip
    flameshot
    unzip
    acpi
    dig
    nix-serve
    xdelta
    pinentry-curses
    bc
    openssl
    powertop
    jq
    yq
    #lsix
    nftables
    iptables

    # File manager
    lf
    ranger

    # Cryptography
    gnupg
    cryptsetup   

    # Editors
    micro
    nano
    
    # For USB devices & windows disks
    ntfs3g
    
    # Net
    tcpdump
    macchanger
    dante
    tsocks
    torsocks
    redsocks
    srelay
    dnsutils

    # Office
    antiword # docx2txt file.docx file.txt
    unoconv # unoconv -fpdf file1.doc

    # Console tools
    qrencode
    qrcp
    dmtx-utils
    figlet
    acpi # battary managment
    cava # audio visualisation
    bat # A cat(1) clone with syntax highlighting and Git integration
    exa # ls clone
    inotify-tools # watch changes in filesystem
    notify-desktop
    st
    psi-notify
    smartmontools
    sysstat

    # For r/unixporn
    neofetch
    cpufetch
    onefetch
    lshw
    inxi
    cmatrix
    sl
    pipes
    tty-clock
    cbonsai

    # Dev
    ansible
    openssl
    openssl.dev
    cookiecutter
    dpkg
    sshfs
    gcc
    gnumake
    gdb
    pkg-config
    go
    # Rust
    rustup
    rustc
    cargo
    cargo-license
    rustfmt
    # Python
    python39Full
    python39Packages.pip
    python39Packages.poetry
    python39Packages.tkinter
    pythonPackages.tkinter
    tk
  ];

  environment.variables = {
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
    HISTCONTROL = "ignoreboth";
    MICRO_CONFIG_HOME = "/etc/micro";
    XDG_DATA_HOME = "/home/admin";
    VISUAL = "micro";
    EDITOR = "micro";
    # constants.Promux1Socks
    #http_proxy = constants.Promux1Socks;
    #https_proxy = constants.Promux1Socks;
    #HTTP_PROXY = constants.Promux1Socks;
    #HTTPS_PROXY = constants.Promux1Socks;
    #socks_proxy = constants.Promux1Socks;
    #SOCKS_PROXY = constants.Promux1Socks;
    #all_proxy = constants.Promux1Socks;
    #ALL_PROXY = constants.Promux1Socks;
  };

  programs.nano = {
    nanorc = ''
      set linenumbers
      set historylog
      set tabsize 2
      set autoindent
      set constantshow
      set nohelp
      set indicator
      set nowrap
      set tabstospaces
      set unix
      set wordbounds
    '';
    syntaxHighlight = true;
  };

  programs = {
    ssh.askPassword = ""; # Ask with CLI but not GUI dialog
  };

  environment.etc.gitignore.source = ./etc/gitignore;
  environment.etc.micro.source = ./configs/micro;
  environment.etc.promux.text = constants.Promux1Addr + "\n[300:4b63:bc3e:f090:babe::]:1080 600ms\n127.0.0.1:6666\n---\n" + constants.Promux2Addr + "\n[300:4b63:bc3e:f090:babe::]:1080 600ms\n" + constants.TorAddr;
  
  systemd.services.basegitsetup = {
    script = ''
      git=${pkgs.git} && $git/bin/git config --system http.proxy socks5://127.0.0.1:0 && $git/bin/git config --system user.name "John Doe" && $git/bin/git config --system user.email "" && $git/bin/git config --system core.excludesfile "/etc/gitignore" &&  $git/bin/git config --global core.editor "nano"
    '';
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {User = "root";};
  };

  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;

  home-manager.users.root = { pkgs, ... }: {
    home.file.".config/micro/settings.json".source = ./configs/micro/settings.json;
    home.file.".config/micro/bindings.json".source = ./configs/micro/bindings.json;
    home.file.".config/htop/htoprc".source = ./configs/htoprc;
    home.file.".config/fish/config.fish".source = ./configs/config.fish;
  };

  home-manager.users.admin = { pkgs, ... }: {
    home.file.".config/micro/settings.json".source = ./configs/micro/settings.json;
    home.file.".config/micro/bindings.json".source = ./configs/micro/bindings.json;
    home.file.".config/htop/htoprc".source = ./configs/htoprc;
    home.file.".config/fish/config.fish".source = ./configs/config.fish;
  };
}
