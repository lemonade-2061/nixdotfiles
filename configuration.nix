# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./kit-vpn.nix              # KIT Remote-VPN (openfortivpn) モジュール
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # 日本語入力 (fcitx5 + mozc)
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
    ];
    fcitx5.waylandFrontend = true;
  };

  # 日本語表示用フォント
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono   # JetBrainsMono + アイコン (kitty/neovim 用)
    nerd-fonts.symbols-only     # 他フォントへアイコンだけ補完 (豆腐対策)
  ];

  # アイコン欠け(豆腐)を全体で防ぐフォールバック設定
  fonts.fontconfig.defaultFonts = {
    monospace = [ "JetBrainsMono Nerd Font" "Noto Sans CJK JP" "Symbols Nerd Font" ];
    sansSerif = [ "Noto Sans CJK JP" "Symbols Nerd Font" ];
    serif     = [ "Noto Serif CJK JP" "Symbols Nerd Font" ];
    emoji     = [ "Noto Color Emoji" ];
  };

  nixpkgs.config.allowUnfree = true;

  # flakes を恒久的に有効化
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Define a user account. Don't forget to set a password with 'passwd'.
  # ユーザーパッケージは home-manager (home.nix) で管理する。
  users.users.lemonade = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # Enable 'sudo' for the user.
    shell = pkgs.zsh; # ログインシェルを zsh に（設定は home.nix の programs.zsh）
  };

  # zsh を /etc/shells に登録（ログインシェルにするのに必須）。
  # 実際のユーザー設定は home-manager 側で行う。
  programs.zsh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data were taken. Do NOT change after install.
  system.stateVersion = "26.05";

  programs.hyprland.enable = true;

  # カーソルテーマ（Bibata: 丸っこい三角形）。SDDM が探せるよう
  # システム側にも入れておく（/run/current-system/sw/share/icons）。
  environment.systemPackages = with pkgs; [
    bibata-cursors
  ];

  # SDDM ログイン画面（Wayland セッションで Hyprland を起動）
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    # ログイン画面でカーソルが出ない対策：明示的にテーマを指定する。
    settings.Theme = {
      CursorTheme = "Bibata-Modern-Classic";
      CursorSize = 24;
    };
  };

  # 既定セッションを「素の Hyprland」に固定する。
  #   programs.hyprland は hyprland.desktop と hyprland-uwsm.desktop の
  #   2つを入れるが、uwsm 版は programs.uwsm.enable が必要で未設定だと
  #   ログイン後に黒画面で落ちる。TTY と同じ素の Hyprland を使う。
  services.displayManager.defaultSession = "hyprland";

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };
}
