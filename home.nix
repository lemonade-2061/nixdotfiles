{ config, pkgs, ... }:

{
  home.username = "lemonade";
  home.homeDirectory = "/home/lemonade";

  # 初回インストール時の NixOS リリースに合わせる。以後変更しない。
  home.stateVersion = "26.05";

  # ------------------------------------------------------------------
  # ユーザーパッケージ（旧 environment.systemPackages / users.*.packages）
  # ------------------------------------------------------------------
  home.packages = with pkgs; [
    # CLI / dev
    git
    neovim
    vim
    tree
    fd
    bat
    btop
    fastfetch
    lolcat
    claude-code

    # ブラウザ
    firefox

    # Wayland / Hyprland デスクトップ
    foot
    kitty
    fuzzel
    waybar
    quickshell
    wl-clipboard
    grim
    slurp
    hyprshot
    satty
    shikane
  ];

  # ------------------------------------------------------------------
  # dotfiles（out-of-store symlink：HM 管理下だが実体は可変ファイル）
  #   → ~/nixos/dotfiles/ を直接編集すれば保存即リロードが効く
  # ------------------------------------------------------------------
  xdg.configFile."hypr/hyprland.lua".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixos/dotfiles/hypr/hyprland.lua";

  xdg.configFile."quickshell/shell.qml".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixos/dotfiles/quickshell/shell.qml";

  programs.home-manager.enable = true;
}
