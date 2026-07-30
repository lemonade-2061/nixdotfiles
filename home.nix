{ config, pkgs, inputs, ... }:

{
  home.username = "lemonade";
  home.homeDirectory = "/home/lemonade";

  home.stateVersion = "26.05";

  #package
  home.packages = with pkgs; [

    # CLI / dev
    git
    neovim
    vim
    gcc          # treesitter などのネイティブビルド用Cコンパイラ
    lazygit      # LazyVim の git 連携
    tree
    fd
    bat
    btop
    fastfetch
    lolcat
    claude-code
    cowsay
    eza
    sd
    ripgrep
    cava
    # starship は programs.starship 側で管理（下部参照）

    # エディタ補助（フォーマッタ / 検索 / ゴミ箱）
    stylua        # Lua フォーマッタ (conform)
    fish          # fish_indent 同梱 (conform)
    fzf           # LazyVim / picker
    ast-grep      # grug-far の拡張検索
    trash-cli     # snacks explorer で安全な削除 (trash コマンド)

    # LSP（言語サーバは nix 側で管理。Mason は NixOS では使わない）
    lua-language-server
    nixd                  # Nix
    bash-language-server
    texlab                # LaTeX
    rust-analyzer
    pyright
    gopls
    # 使う言語が増えたらここに追記（例: pyright, rust-analyzer, gopls ...）

    # snacks.image レンダリング用
    ghostscript   # gs（PDF）
    tectonic      # LaTeX 数式
    mermaid-cli   # mmdc（Mermaid 図）


    # ブラウザ
    firefox
    inputs.zen-browser.packages.${pkgs.system}.default   # Zen Browser (flake input 経由)
    chromium
    google-chrome   # Google アカウント同期用（unfree）

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

  # カーソルテーマ（Bibata-Modern-Classic）。
  # GTK / X11(XWayland) / Hyprland すべてに XCURSOR_* を通す。
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # dotfiles symlink
  xdg.configFile."hypr/hyprland.lua".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixos/dotfiles/hypr/hyprland.lua";

  xdg.configFile."quickshell/shell.qml".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixos/dotfiles/quickshell/shell.qml";

  xdg.configFile."kitty/kitty.conf".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixos/dotfiles/kitty/kitty.conf";

  # Neovim (LazyVim) を丸ごと symlink。lazy-lock.json 等の書き込みも
  # そのまま ~/nixos/dotfiles/nvim に反映され git 管理できる。
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixos/dotfiles/nvim";

  # 共通エイリアス（bash / zsh 両方に流し込む）
  # bash はフォールバック用に残しておく。
  programs.bash = {
    enable = true;
    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake /home/lemonade/nixos#nixos";
      nrl = "nixos-rebuild list-generations";
      "kit-vpn" = "sudo openfortivpn -c /etc/openfortivpn/kit";
    };
  };

  # zsh: 既定のログインシェル
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;       # 履歴からの薄字サジェスト
    syntaxHighlighting.enable = true;   # コマンドの色付け
    enableCompletion = true;
    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
    };
    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake /home/lemonade/nixos#nixos";
      nrl = "nixos-rebuild list-generations";
      "kit-vpn" = "sudo openfortivpn -c /etc/openfortivpn/kit";
    };
  };

  # starship: クロスシェルプロンプト。zsh 連携は既定で有効。
  # 初期設定は最小限（デフォルトプロンプト + 改行なし）。
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
    };
  };

  programs.home-manager.enable = true;
}
