# デスクトップ (Arch Linux + Hyprland) 用。standalone Home Manager で使う。
#   適用: home-manager switch --flake ~/projects/nixdotfiles#lemonade@desktop
#     (または nh home switch ~/projects/nixdotfiles)
#
# 役割分担:
#   - pacman : システム / GPU / 音 / Hyprland 周り / fcitx5 / フォント / GUI アプリ全般
#   - ここ    : common.nix の CLI・開発ツールと LSP
# GUI アプリを nix で入れると fcitx5 (IM モジュール) や Mesa と噛み合わないので入れない。
# シェルや各アプリの設定ファイルは当面 ~/projects/dotfiles (stow) のまま。
{ ... }:

{
  imports = [ ./common.nix ];

  home.username = "lemonade";
  home.homeDirectory = "/home/lemonade";

  home.stateVersion = "26.05";

  # 非 NixOS 向けの調整 (XDG_DATA_DIRS に nix 側の share を足す等)
  targets.genericLinux.enable = true;
  # GPU ドライバ連携 (/run/opengl-driver) は nix 製 GUI アプリ用で sudo のセットアップが要る。
  # GUI は pacman 側なので不要。
  targets.genericLinux.gpu.enable = false;

  programs.home-manager.enable = true;
}
