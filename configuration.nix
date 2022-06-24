{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  services.blueman.enable = true;
  services.hardware.bolt.enable = true;

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", MODE="0666", RUN+="${pkgs.coreutils}/bin/chmod a+w /sys/class/backlight/%k/brightness"
  '';

  powerManagement.enable = false;
  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: rec { neovim = (import ./nvim.nix);};
  };
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "intel_pstate=active" ];

  nix = {
    trustedUsers = ["jamie"];
  # haskell2nix binary cache
    settings.trusted-public-keys = [ "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" ];
    settings.substituters = [ "https://hydra.iohk.io" ];

    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  programs.light.enable = true;
  services.journald.extraConfig = "SystemMaxUse=2G";

  systemd = {
#   services."nogpe06" = { script = ''/bin/sh -c "echo disable > /home/jamie/nogpe06"''; };
#   services."NetworkManager-wait-online".wantedBy = lib.mkForce [];
    services.mongodb.enable = true;
    extraConfig = "DefaultTimeoutStopSec=5s";
#   services."systemd-timesyncd".wantedBy = lib.mkForce [];
# Don't wait for network
    targets.network-online.wantedBy = pkgs.lib.mkForce []; # Normally ["multi-user.target"]
    services.NetworkManager-wait-online.wantedBy = pkgs.lib.mkForce []; # Normally ["network-online.target"]
    };

  fonts.fonts = with pkgs; [ wqy_zenhei noto-fonts-cjk source-han-sans-traditional-chinese ];
  fonts.fontconfig.enable = true;
  console.font = "sun12x22";
  console.keyMap = "fr_CH-latin1";
  i18n = {
  # consoleFont = "Lat2-Terminus16";
  # defaultLocale = "en_US.UTF-8";
    defaultLocale = "zh_TW.UTF-8";
    supportedLocales = [ "zh_TW.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];
    inputMethod = {
      enabled = "fcitx5";
#     fcitx.engines = with pkgs.fcitx5-engines; [ fcitx5-table-extra fcitx5-chinese-addons table-extra ];
      fcitx5.addons = with pkgs; [ fcitx5-chinese-addons fcitx5-table-extra fcitx5-rime fcitx5-table-extra ];
    };
  };

  time.timeZone = "Europe/Paris";
  environment = {
    systemPackages = with pkgs; let
      xorgPkgs = [google-chrome firefox dmenu polybar dunst scrot mpv evince okular diffpdf xfce.xfce4-terminal chessx pasystray playerctl pamixer alacritty networkmanagerapplet tmux
      ];
    in [
      j
#     (j.overrideAttrs (oldAttrs: { postInstall = ''jconsole <<< "install 'plot'"<''; }))
      stdenv zsh lazygit
      wget curl git htop pstree zip unzip unrar lsof nmap
      fzf fd ripgrep tree neovim dhcpcd brightnessctl
      man-pages nox ranger texlive.combined.scheme-basic
      pciutils
      j
#     agdaWithPackages
      stockfish
      cachix

#     thunderbolt usbutils lshw
    ] ++ (if config.services.xserver.enable then xorgPkgs else []);
    
    pathsToLink = [ "/share/agda" ];
    variables = {
#     GIO_EXTRA_MODULES = [ "${pkgs.xfce.gvfs}/lib/gio/modules" ];
      EDITOR = "nvim";
#     TERMINAL = "xfce4-terminal";
      TERMINAL = "alacritty";
      CACHIX_AUTH_TOKEN = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJjJDI5NjUiLCJqdGkiOiIyNDc3MmJiMC0yYmFhLTQwMzItYjViNi03YTFlNjkwZDVlZDgiLCJzY29wZXMiOiJjYWNoZSJ9.UIE0NrDx8Xt3mkQY9GIw3Orz7HmXAU7A9t7dnpjXmiU";
    };
  };

  programs = {
    zsh = {
      enable = true;
      shellAliases = { vim = "nvim"; };
      enableCompletion = true;
      autosuggestions.enable = true;
      interactiveShellInit = ''
        export ZSH_THEME="lambda"
        source /etc/nixos/dotfiles/zshrc
        '';
      promptInit="";
    };
  };

  services.logind.extraConfig = "idleAction=ignore";
# services.acpid.enable = true;
  services.resolved.enable = lib.mkForce false;
  networking = {
    networkmanager.enable = true;
    hostName = "J4-Mac";
    nameservers = ["9.9.9.9" "1.1.1.1" "1.0.0.1"];
#   interfaces.wlp2s0.useDHCP = true;
#     enp0s20u1u4.useDHCP = true;
  };
# environment.etc."resolv.conf" = {
#   text = lib.optionalString (config.networking.nameservers != []) (
#              lib.concatMapStrings (ns: "nameserver ${ns}\n") config.networking.nameservers);
#                         mode = "0444"; };

  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.bluetooth.enable = true;
  services = {
  # openssh.enable  = true;
    compton.enable  = true;

    # Printing
    printing.enable = true;
    printing.drivers = [ pkgs.gutenprint ];
    avahi.enable = true;
    avahi.nssmdns = true;

    xserver.enable  = true;
  };
  services.xserver = {
#   xrandrHeads = [ 
#     { output = "eDP-1";  monitorConfig = ''Option "DPI" "96 x 96"'' ; }
#     { output = "HDMI-3"; monitorConfig = ''Option "above" "eDP-1"''; }
#   ];
    libinput.enable = true;
#   multitouch.enable = true;
#   config = (builtins.readFile ./dotfiles/mtrack.conf);
    autorun = false;
    exportConfiguration = true;
    xkbOptions = "eurosign:e";
    layout = "ch";
    autoRepeatInterval = 200;
    autoRepeatDelay = 130;

    displayManager.startx.enable = true;
    displayManager.defaultSession="none+xmonad";
#   desktopManager = {
#     xterm.enable = false;
#     xfce = {
#       enable = true;
#       noDesktop = true;
#       enableXfwm = false;
#     };
#   };
    windowManager = {
      xmonad = {
        enable = true;
        enableContribAndExtras = true;
      };
    };
  };

  users = {
    defaultUserShell = pkgs.zsh;
    users.jamie = {
      isNormalUser = true;
      extraGroups = [ "audio" "sound" "tty" "wheel" "docker" "networkmanager" "video" "input" ];
      };
  };

  virtualisation.docker.enable = false;
  system.stateVersion = "19.09"; # Don't touch prematurely
}
