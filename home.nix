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
    awscli2      # AWS CLI v2
    rustc
    cargo
    rustfmt
    clippy
    cmatrix
    jq           # JSON 加工
    unzip
    p7zip
    nvd          # 世代間の差分表示 (nvd diff /run/current-system result)
    nix-output-monitor # nom: ビルドログをツリー表示
    nh           # nixos-rebuild ラッパー (nh os switch ~/nixos)
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

    # ビューア / ファイルマネージャ
    mpv           # 動画
    imv           # 画像
    zathura       # PDF
    yazi          # TUI ファイルマネージャ


    # ブラウザ
    firefox
    inputs.zen-browser.packages.${pkgs.system}.default   # Zen Browser (flake input 経由)
    chromium
    google-chrome   # Google アカウント同期用（unfree）

    # ソフト
    # XWayland だとスケール1.5でぼやけるのでネイティブ Wayland で起動
    (symlinkJoin {
      name = "spotify-wayland";
      paths = [ spotify ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/spotify \
          --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
      '';
    })

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
    swww          # 壁紙デーモン（中身はawww: awww img <画像> で切り替え）
    pavucontrol   # 音量・出力先切替 GUI
    cliphist      # クリップボード履歴 (Super+SHIFT+V で fuzzel ピッカー)
    libnotify     # notify-send (通知はquickshellのNotificationDaemonが受ける)
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

  # dotfiles symlink（ディレクトリ丸ごと — binds.lua 等の分割ファイルも含める）
  xdg.configFile."hypr".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixos/dotfiles/hypr";

  # ディレクトリ丸ごと symlink（bar/ 等の分割ファイルも含める）
  xdg.configFile."quickshell".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixos/dotfiles/quickshell";

  # kitty もディレクトリ丸ごと symlink（kitten themes が書く
  # current-theme.conf 等も dotfiles/kitty に入り git 管理できる）
  xdg.configFile."kitty".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixos/dotfiles/kitty";

  # Neovim (LazyVim) を丸ごと symlink。lazy-lock.json 等の書き込みも
  # そのまま ~/nixos/dotfiles/nvim に反映され git 管理できる。
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixos/dotfiles/nvim";

  # fastfetch: config.jsonc を直接編集すれば次回実行から即反映
  xdg.configFile."fastfetch".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixos/dotfiles/fastfetch";

  # 共通エイリアス（bash / zsh 両方に流し込む）
  # bash はフォールバック用に残しておく。
  programs.bash = {
    enable = true;
    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake /home/lemonade/nixos#nixos";
      nrl = "nixos-rebuild list-generations";
      "kit-vpn" = "sudo openfortivpn -c /etc/openfortivpn/kit";
      lsa = "eza -la --icons --git --group-directories-first --time-style=long-iso";
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
      lsa = "eza -la --icons --git --group-directories-first --time-style=long-iso";
    };

    # 金沢工大の学内 Wi-Fi (KIT-WLAP2) は学外通信にプロキシ必須。
    # シェル起動時に接続中なら自動で環境変数をセットする。
    # Wi-Fi を途中で切り替えたシェルでは kit-proxy-on / kit-proxy-off で手動切替。
    initContent = ''
      # kitty shell integration (OSC 133 プロンプトマーク) の手動ロード。
      # これが無いとリサイズで折り返したプロンプトを kitty が消去できず、
      # 同じ行が下に複製される (starship のバグではなく統合未ロードが原因)。
      if [[ -n "$KITTY_INSTALLATION_DIR" ]]; then
        export KITTY_SHELL_INTEGRATION="no-rc"
        autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
        kitty-integration
        unfunction kitty-integration
      fi

      kit-proxy-on() {
        export http_proxy=http://wwwproxy-a10.kanazawa-it.ac.jp:8080
        export https_proxy=$http_proxy HTTP_PROXY=$http_proxy HTTPS_PROXY=$http_proxy
        export no_proxy=localhost,127.0.0.1,.kanazawa-it.ac.jp
        export NO_PROXY=$no_proxy
      }
      kit-proxy-off() {
        unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY
      }
      if nmcli -t -f NAME connection show --active 2>/dev/null | grep -qx 'KIT-WLAP2'; then
        kit-proxy-on
      fi
    '';
  };

  # starship: クロスシェルプロンプト。zsh 連携は既定で有効。
  # settings は使わず dotfiles/starship/starship.toml を直接編集する
  # （Rosé Pine Moon テーマ + add_newline = false）。
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
  xdg.configFile."starship.toml".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixos/dotfiles/starship/starship.toml";

  # zoxide: cd の学習型ジャンプ (z <dir>)。zsh 連携は既定で有効。
  programs.zoxide.enable = true;

  # direnv + nix-direnv: プロジェクトの .envrc (`use flake` 等) で
  # dev shell を自動ロード。nix-direnv 側は評価結果をキャッシュする。
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # 通知デーモンは quickshell が実装 (dotfiles/quickshell/notifications/)。
  # mako 等を有効にすると org.freedesktop.Notifications を取り合うので入れない。

  # USB 自動マウント（udisks2 は configuration.nix 側で有効化）。
  # バーに SNI トレイがないので tray は切っておく。
  services.udiskie = {
    enable = true;
    tray = "never";
  };

  # polkit 認証エージェント。GUI からの管理者権限要求のダイアログ担当。
  # パッケージは bin/ を持たず libexec 配下のみなので直接パスを指定。
  systemd.user.services.hyprpolkitagent = {
    Unit = {
      Description = "Hyprland polkit authentication agent";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  programs.home-manager.enable = true;
}
