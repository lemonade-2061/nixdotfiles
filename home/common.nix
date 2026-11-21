# ラップトップ (NixOS) とデスクトップ (Arch + standalone Home Manager) で共有する部分。
#
# ここに置くのは「どのディストリでもそのまま動く」CLI / 開発ツールだけ。
# GUI アプリ (GPU・fcitx5・フォント連携が要る) や、シェル設定・symlink のように
# マシンごとに管理方法が違うものは laptop.nix / desktop.nix 側に置く。
{ pkgs, ... }:

{
  home.packages = with pkgs; [

    # CLI / dev
    git
    neovim
    vim
    lazygit      # LazyVim の git 連携
    gh           # GitHub CLI（PR レビュー等）
    tree
    fd
    bat
    btop
    fastfetch
    hyfetch      # neofetch 後継 (素の見た目は neowofetch コマンド)
    lolcat
    cowsay
    cava
    # ターミナル用スクリーンセーバー
    cmatrix
    cbonsai       # 盆栽 (cbonsai -l でライブ成長、-S でスクリーンセーバーモード)
    pipes-rs      # pipes.sh の Rust 版
    asciiquarium-transparent  # 水族館 (-t で背景透過)
    tty-clock     # デジタル時計 (tty-clock -sc)
    terminal-parrot  # パーティーパロット
    eza
    sd
    ripgrep
    jq           # JSON 加工
    tokei        # 行数カウント
    unzip
    p7zip
    yazi         # TUI ファイルマネージャ
    awscli2      # AWS CLI v2
    # ローカルサーバを https の公開 URL に出すトンネル (ハッカソンでスマホから叩く用)。
    # unfree なので allowUnfree 前提。authtoken は
    # ngrok config add-authtoken <token> で ~/.config/ngrok/ngrok.yml に入る (Nix 管理外)。
    ngrok

    # Nix 周り
    nvd          # 世代間の差分表示 (nvd diff /run/current-system result)
    nix-output-monitor # nom: ビルドログをツリー表示
    nh           # nixos-rebuild / home-manager ラッパー (nh os switch / nh home switch)
    nixfmt       # Nix フォーマッタ

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

    # プロジェクト単位の Python 環境。uv venv && uv pip install <名前>
    uv

    # LSP（言語サーバは nix 側で管理。Mason は使わない）
    lua-language-server
    nixd                  # Nix
    bash-language-server
    shellcheck            # bash-language-server が診断に使う
    yaml-language-server
    vscode-langservers-extracted # JSON / HTML / CSS / ESLint
    vtsls                 # TypeScript
    astro-language-server
    texlab                # LaTeX
    rust-analyzer
    pyright
    gopls
    # Kotlin (JetBrains 公式の kotlin-lsp。nixpkgs に無いので pkgs/ で自前パッケージ化)
    (callPackage ../pkgs/kotlin-lsp.nix { })
    # 使う言語が増えたらここに追記（nix search nixpkgs#<名前> で探す）

    # snacks.image レンダリング用
    ghostscript   # gs（PDF）
    tectonic      # LaTeX 数式
    mermaid-cli   # mmdc（Mermaid 図）
  ];

  # 既定エディタを nvim に（git commit / crontab -e 等もこれを見る）
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
