# ブートチェーン構成:
#   ファームウェア → Visor (メインのブートマネージャ、ESP に手動インストール)
#                    ├─ NixOS (最新世代のカーネルを EFI stub で直接起動)
#                    ├─ Windows (別ディスクの ESP を PARTUUID で指定)
#                    └─ systemd-boot (フォールバック、全世代の選択メニュー)
#
# 世代選択は systemd-boot に任せ、Visor の NixOS エントリは常に最新世代を
# 直接起動する。以前あった standalone GRUB のチェインロードは廃止した
# (世代メニューが systemd-boot と二重だったため)。
#
# systemd-boot は NixOS 管理 (boot.loader.systemd-boot.enable) のまま残す。
# 毎リビルドでカーネル/initrd を ESP の /EFI/nixos/ にコピーし、
# /boot/loader/entries に全世代の BLS エントリを生成してくれるので、
#   - フォールバックとして常に全世代をブートできる
#   - Visor の NixOS エントリもこのコピー済みカーネルを使える (ESP は FAT
#     なので efifs ドライバ不要で UEFI から読める)
#
# Visor の boot.conf は extraInstallCommands (systemd-boot のインストーラの
# 直後、switch でも boot でも走る) で毎リビルド生成する。理由:
#   - 「最新世代のカーネル/initrd の ESP 上のパスと init=」は Nix の評価時
#     には確定できない (toplevel への参照が循環する) ので、インストーラが
#     書いた loader.conf のデフォルト世代の BLS エントリを読んで Visor 形式
#     に変換する。
#   - boot.conf に entry を1つでも書くと Visor の自動検出 (BLS 追従) が
#     完全に無効になる仕様のため、全エントリを宣言的に書き切る。
# アイコン等の静的ファイルは extraFiles (マーカー管理) で配置する。
#
# Visor 本体 (visor_x64.efi + アイコン類) は upstream の install.sh で
# 導入・更新する (install.sh は既存の boot.conf を上書きしない)。

{ config, lib, pkgs, ... }:

let
  winEspPartUuid = "906836d3-1ed2-4241-bddd-71c515c86266"; # Windows の ESP (nvme1n1p1, PARTUUID)

  # /EFI/visor/boot.conf を生成する。引数で ESP ルートを差し替え可能
  # (テスト用)。デフォルト世代の BLS エントリが読めないときは systemd-boot
  # へのチェインロードにフォールバックする。
  # 注意 (Visor のパーサ仕様):
  #   - entry ブロック内に空行を入れない (空行でブロックが打ち切られる)
  #   - グローバルの cmdline= は設定しない (チェインロード先の EFI に
  #     LoadOptions として渡ってしまう)
  #   - パスは ESP ルートからの絶対パス、区切りはバックスラッシュ
  visorMenuGen = pkgs.writeShellScript "generate-visor-boot-conf" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.gnused ]}

    esp="''${1:-/boot}"
    out="$esp/EFI/visor/boot.conf"
    mkdir -p "$esp/EFI/visor"

    # systemd-boot がデフォルトにしている世代 (= 今回ビルドした世代) の
    # BLS エントリから kernel / initrd / options を拾う
    kernel=""; initrd=""; cmdline=""
    defaultEntry=$(sed -n 's/^default[[:space:]]*//p' "$esp/loader/loader.conf" | head -n1)
    if [ -n "$defaultEntry" ] && [ -r "$esp/loader/entries/$defaultEntry" ]; then
      bls="$esp/loader/entries/$defaultEntry"
      kernel=$(sed -n 's/^linux[[:space:]]*//p' "$bls" | head -n1)
      initrd=$(sed -n 's/^initrd[[:space:]]*//p' "$bls" | head -n1)
      cmdline=$(sed -n 's/^options[[:space:]]*//p' "$bls" | head -n1)
    fi

    {
      cat <<'EOF'
# NixOS が生成 (nixos/boot.nix の visorMenuGen)。手編集しても次の rebuild で上書きされる。
timeout=5
default=0
snapshots=0
background=\EFI\visor\backgrounds\default.png
EOF
      if [ -n "$kernel" ] && [ -n "$initrd" ]; then
        printf '\nentry {\n'
        printf '    name    = "NixOS"\n'
        printf '    icon    = %s\n' '\EFI\visor\icons\nixos.png'
        printf '    kernel  = %s\n' "''${kernel//\//\\}"
        printf '    initrd  = %s\n' "''${initrd//\//\\}"
        printf '    cmdline = "%s"\n' "$cmdline"
        printf '}\n'
      else
        echo "generate-visor-boot-conf: BLS エントリを読めなかったので NixOS エントリは systemd-boot チェインにフォールバック" >&2
        cat <<'EOF'

entry {
    name   = "NixOS"
    icon   = \EFI\visor\icons\nixos.png
    kernel = \EFI\systemd\systemd-bootx64.efi
}
EOF
      fi
      cat <<'EOF'

entry {
    name   = "Windows"
    icon   = \EFI\visor\icons\windows.png
    kernel = \EFI\Microsoft\Boot\bootmgfw.efi
    uuid   = ${winEspPartUuid}
}

entry {
    name   = "systemd-boot"
    icon   = \EFI\visor\icons\linux.png
    kernel = \EFI\systemd\systemd-bootx64.efi
}
EOF
    } > "$out".tmp
    mv "$out".tmp "$out"
  '';
in
{
  # フォールバック用ブートローダー (NixOS 管理)。世代選択メニューはこちら。
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.systemd-boot.extraFiles = {
    "EFI/visor/icons/nixos.png" =
      "${pkgs.nixos-icons}/share/icons/hicolor/128x128/apps/nix-snowflake.png";
  };

  # Visor のメニュー (/EFI/visor/boot.conf) をリビルドごとに再生成する。
  # このファイルは extraFiles のマーカー管理外なので、この構成をやめる
  # ときは手で消すこと。
  boot.loader.systemd-boot.extraInstallCommands = ''
    ${visorMenuGen}

    # 一時的な掃除: 旧 standalone GRUB 構成の名残。grubx64.efi は extraFiles
    # のマーカー経由で自動削除されるが、grub.cfg はマーカー管理外だったので
    # ここで消す。/boot/EFI/grub が消えたらこのブロックは削除してよい。
    ${pkgs.coreutils}/bin/rm -f /boot/EFI/grub/grub.cfg
    ${pkgs.coreutils}/bin/rmdir /boot/EFI/grub 2>/dev/null || true
  '';

  # systemd-boot 側からも Visor へ戻れるようにしておく
  # (sort-key で NixOS 世代エントリの後ろに並べる)。
  boot.loader.systemd-boot.extraEntries = {
    "visor.conf" = ''
      title Visor
      sort-key z-visor
      efi /EFI/visor/visor_x64.efi
    '';
  };

  # Visor の install.sh がブートエントリ登録に使う。
  environment.systemPackages = [ pkgs.efibootmgr ];
}
