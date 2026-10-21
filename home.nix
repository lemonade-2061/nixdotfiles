{ config, pkgs, inputs, ... }:

let
  # bash / zsh 共通のエイリアス。bash はフォールバック用に残してある。
  commonAliases = {
    nrs = "sudo nixos-rebuild switch --flake /home/lemonade/nixos#nixos";
    nrl = "nixos-rebuild list-generations";
    "kit-vpn" = "sudo openfortivpn -c /etc/openfortivpn/kit";
    lsa = "eza -la --icons --git --group-directories-first --time-style=long-iso";
    # 画面クリア後にスクロールバックも消す (2J=画面 3J=履歴 H=カーソル復帰)
    clear = "printf '\\033[2J\\033[3J\\033[H'";
    # Tailscale 経由でデスクトップ (archlinux) へ。noVNC 用に 6080 をフォワード。
    "desktop-ssh" = "ssh -L 6080:localhost:6080 lemonade@100.108.23.90";
    # 学内プリンター (iogate3 / RICOH SP C840)。詳細は ~/nixos/kit-printer.md
    kprint = "lp -d netpr01c";          # kprint ファイル で送信
    kpq = "lpstat -W not-completed -o"; # 詰まっていないか確認
  };
in
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
    codex
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
    hyfetch      # neofetch 後継 (素の見た目は neowofetch コマンド)
    # adb / fastboot。システム側の設定は不要 (NixOS 26.05 で programs.adb は
    # 廃止。systemd 258 が USB デバイスへの uaccess を自動で付けるため)。
    android-tools
    # starship は programs.starship 側で管理（下部参照）

    # エディタ補助（フォーマッタ / 検索 / ゴミ箱）
    stylua        # Lua フォーマッタ (conform)
    fish          # fish_indent 同梱 (conform)
    fzf           # LazyVim / picker
    ast-grep      # grug-far の拡張検索
    trash-cli     # snacks explorer で安全な削除 (trash コマンド)
    prettier      # prettier extra (conform)
    black         # Python フォーマッタ (black extra)
    tree-sitter   # nvim-treesitter main ブランチのパーサーコンパイルに必須
    sqlite        # snacks picker の frecency / 履歴保存

    # Python 本体 + よく使うライブラリ。
    # NixOS ではシステムの Python に pip install できない (store が読み取り専用)
    # ので、常用するものはここに宣言して入れる。追加したいときはこのリストに
    # 足して nrs。利用できる名前は: nix search nixpkgs#python3Packages.<名前>
    (python3.withPackages (ps: with ps; [
      numpy
      matplotlib
      pandas
      scipy
      ipython
    ]))
    # nixpkgs に無いパッケージや、プロジェクト単位で固めたいときはこちら。
    # uv venv && uv pip install <名前>  で普通に pip が使える。
    uv

    # LSP（言語サーバは nix 側で管理。Mason は NixOS では使わない）
    lua-language-server
    nixd                  # Nix
    bash-language-server
    texlab                # LaTeX
    rust-analyzer
    pyright
    gopls
    # 使う言語が増えたらここに追記（nix search nixpkgs#<名前> で探す）

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
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default   # Zen Browser (flake input 経由)
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
    blender
    zoom-us
    # Word/Excel/PowerPoint 互換オフィス。LibreOffice と違い OOXML を
    # ネイティブに扱う（内部が Word と同じ docx モデル）ので、docx を
    # 開いて PDF 書き出ししてもページ送りや表組みが崩れにくい。
    onlyoffice-desktopeditors
    # vscode は programs.vscode (vscode-fhs) 側で入れる

    # Wayland デスクトップ (ShojiWM / Hyprland 共通)
    foot
    kitty
    fuzzel
    # 自作 Quickshell バーの実行環境。常用は下の noctalia だが、
    # dotfiles/quickshell + ~/.config/shojiwm/src/index.tsx のコメントアウト部で
    # いつでも戻せるようにしてある。壁紙ピッカーもこちら。
    quickshell
    # Noctalia v5 (ネイティブ C++ / OpenGL ES の Wayland シェル)。
    # v4 系 (noctalia-shell + noctalia-qs) は Quickshell/Qt ベースで EOL。
    # upstream の noctalia-qs は 2026-07-15 にアーカイブ済みなので、
    # 最初から v5 に寄せる (2026-10-15 移行)。
    # 注意: v4 とは互換性が無い。バイナリ名 noctalia-shell -> noctalia、
    # 設定 JSON -> TOML、IPC `noctalia-shell ipc call ...` -> `noctalia msg ...`。
    # 設定は ~/.config/noctalia/config.toml (手書き層) と
    # ~/.local/state/noctalia/settings.toml (GUI が書く層、こちらが優先)。
    noctalia
    wl-clipboard
    grim
    slurp
    hyprshot
    satty
    shikane
    awww          # 壁紙デーモン (旧 swww。awww img <画像> で切り替え)
    pavucontrol   # 音量・出力先切替 GUI
    cliphist      # クリップボード履歴 (Super+SHIFT+V で fuzzel ピッカー)
    libnotify     # notify-send (通知は noctalia が受ける)
    obs-studio    # 配信・録画 (画面キャプチャはxdg-desktop-portal経由)
    brightnessctl # 輝度キー (XF86MonBrightness*) 用
  ];

  # カーソルテーマ（Bibata-Modern-Classic）。
  # GTK / X11(XWayland) / コンポジタすべてに XCURSOR_* を通す。
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # dotfiles symlink。mkOutOfStoreSymlink なので ~/nixos 側を直接編集すれば
  # rebuild なしで反映される。
  #
  # hypr: フォールバックの Hyprland 用（常用の ShojiWM は ~/.config/shojiwm の
  # TSX 設定を使うので、こちらは Hyprland セッションを選んだときだけ効く）。
  xdg.configFile."hypr".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixos/dotfiles/hypr";

  # quickshell: 自作バー (bar/) と通知デーモンと壁紙ピッカー。現在バーは
  # noctalia に任せているため、ShojiWM 側から起動しているのは壁紙ピッカーのみ。
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

  # 既定エディタを nvim に（git commit / crontab -e 等もこれを見る）
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  programs.bash = {
    enable = true;
    shellAliases = commonAliases;
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
    shellAliases = commonAliases;

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

  # OnlyOffice は fontconfig を使わず自前で /usr/share/fonts・
  # /usr/local/share/fonts・~/.fonts を走査する。そのうえで走査時に
  # シンボリックリンクを読み飛ばすため、フォントが全部 store への
  # リンクである NixOS では和文が一本も見つからず豆腐になる。
  # (実測: ~/.fonts に実ファイルを置くと拾われ、リンクだと無視された)
  #
  # 対策として実ファイルをコピーしたディレクトリを ~/.fonts に置く。
  # ディレクトリ自体はリンクでも中身が実ファイルなら走査される。
  home.file.".fonts".source = pkgs.runCommand "onlyoffice-real-fonts" { } ''
    mkdir -p $out
    for d in ${pkgs.noto-fonts-cjk-sans} ${pkgs.noto-fonts-cjk-serif} \
             ${pkgs.ipaexfont} ${pkgs.corefonts} ${pkgs.vista-fonts}; do
      find -L "$d/share/fonts" -type f \
        \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.ttc' -o -iname '*.otc' \) \
        -exec cp -Lf -t $out {} +
    done
  '';

  # VSCode。中身は Microsoft 公式ビルドだが、素の pkgs.vscode ではなく
  # FHS 環境で起動する pkgs.vscode-fhs を使う。拡張機能が同梱している
  # プリビルドバイナリ (cpptools の clangd/gdb、Pico 拡張のツールチェーン等) が
  # /lib64/ld-linux-x86-64.so.2 を探して動かないのを避けるため。
  #
  # Wayland ネイティブで起動したい場合は NIXOS_OZONE_WL=1 が必要
  # (nixpkgs の wrapper がこれを見て --ozone-platform-hint=auto を足す)。
  # Electron アプリ全体に効く変更なので、入れるなら home.sessionVariables 側で。
  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs;

    # GUI のマーケットプレイスからも拡張を入れられるようにしておく。
    # nixpkgs に無い拡張 (例: Raspberry Pi Pico) はこちらから入れる。
    mutableExtensionsDir = true;

    profiles.default = {
      # nix 側で固定する拡張。GUI 経由で入れたものと共存する。
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide        # Nix (LSP は nixd を使う。userSettings 参照)
        rust-lang.rust-analyzer   # Rust
        ms-python.python          # Python
        tamasfe.even-better-toml  # TOML (Cargo.toml 等)
        ms-vscode.cpptools        # C/C++ (pico の C SDK 用)
        ms-vscode.cmake-tools     # CMake
        vscodevim.vim             # vim キーバインド
      ];

      userSettings = {
        # 言語サーバは home.packages 側で入れたものを PATH 経由で使う。
        # 拡張機能に自動ダウンロードさせる方式は NixOS では動かない (Mason と同じ理由)。
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nixd";

        "editor.fontFamily" = "'JetBrainsMono Nerd Font', monospace";
        "editor.fontLigatures" = true;
        "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
        "files.trimTrailingWhitespace" = true;
        "files.insertFinalNewline" = true;
      };

      # 更新は nixos-rebuild 側でやるので、アプリ内の更新チェックは切る。
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
    };
  };

  # 通知は noctalia が org.freedesktop.Notifications を取る。
  # dotfiles/quickshell/notifications/ の自作デーモンは Quickshell バーに
  # 戻すとき用。mako 等を足すと名前を取り合うので入れない。

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
