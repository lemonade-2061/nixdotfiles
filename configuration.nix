# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./boot.nix                 # ブートチェーン (Visor / GRUB / systemd-boot)
      ./kit-vpn.nix              # KIT Remote-VPN (openfortivpn) モジュール
    ];

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # 圧縮スワップ (zram) — RAMの50%をzstd圧縮のswapとして使う
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
  # zramがあるうちは積極的にswapさせる (圧縮なので安価)
  boot.kernel.sysctl."vm.swappiness" = 180;

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

  # コンテナ環境: rootless Podman + Docker 互換レイヤ。
  # ハッカソン用リポジトリ (~/hackathon) を docker compose で動かすため。
  # - dockerCompat: `docker` コマンドを podman のエイリアスとして提供
  # - rootless の subuid/subgid は users.users 側で自動設定済み (/etc/subuid)
  # - `docker compose` / `podman compose` は外部の docker-compose を実体として呼び出し、
  #   その際 rootless ソケットへの DOCKER_HOST は podman が自動設定する
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    # compose が作るネットワークでサービス名の DNS 解決 (backend→db 等) を有効にする
    defaultNetwork.settings.dns_enabled = true;
  };

  # カーソルテーマ（Bibata: 丸っこい三角形）。SDDM が探せるよう
  # システム側にも入れておく（/run/current-system/sw/share/icons）。
  environment.systemPackages = with pkgs; [
    bibata-cursors
    docker-compose # `docker compose` / `podman compose` の実体 (compose v2)
  ];

  # SDDM ログイン画面（Wayland セッションで Hyprland を起動）
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    # グリータ用コンポジタは kwin。既定の weston 15 は drm-backend の
    # HW カーソルプレーンが AMD 780M で透明表示になるバグがあり、カーソルが
    # 見えない（ネスト weston + 同一 greeter + 同一 env では正常表示を実験で
    # 確認済み → クライアント側ではなく weston の合成が原因）。
    wayland.compositor = "kwin";
    # Theme.CursorTheme/CursorSize は daemon が XCURSOR_THEME/SIZE として
    # greeter 環境に注入する。xcursor の既定探索パス（~/.icons 等）は
    # sddm ユーザーでは全て空なので XCURSOR_PATH を明示。
    settings.Theme = {
      CursorTheme = "Bibata-Modern-Classic";
      CursorSize = 24;
    };
    # この行はモジュールが kwin 選択時に入れる既定の GreeterEnvironment
    # （QT_WAYLAND_SHELL_INTEGRATION=layer-shell）を丸ごと上書きするため、
    # layer-shell も自分で併記する。XDG_DATA_DIRS は kwin 自身の
    # カーソルテーマ探索用（kwin は XCURSOR_PATH ではなく XDG を見る）。
    settings.General.GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell,XCURSOR_PATH=/run/current-system/sw/share/icons,XDG_DATA_DIRS=/run/current-system/sw/share";
  };

  # SDDM テーマ (qylock flake)。The Last of Us Part II テーマを使用。
  # テーマ本体と必要な QML モジュール (qt5compat/multimedia/svg) は
  # qylock の NixOS モジュールが sddm.extraPackages に追加してくれる。
  programs.qylock = {
    enable = true;
    theme = "last-of-us";
    quickshell.enable = false; # SDDM テーマだけ使う（ロック画面は未使用）
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

  # USB 等の自動マウント基盤（フロントエンドは home.nix の udiskie）
  services.udisks2.enable = true;
}
