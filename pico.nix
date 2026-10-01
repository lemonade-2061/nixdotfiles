# RaspberryPi Pico (RP2040) 開発環境 — システム側の設定。
#
# 鷹合研究室の手順書は Windows + VsCode + 「Raspberry Pi Pico」拡張機能が前提だが、
# 拡張機能がやっているのは結局
#   1. pico-sdk / arm-none-eabi-gcc / cmake / ninja / picotool の取得
#   2. cmake 構成 → ninja でビルド        (Compile ボタン)
#   3. picotool で .uf2 を書き込み         (RUN ボタン)
#   4. シリアルモニタ表示
# の4つなので、NixOS では 1 を devShell (flake.nix の devShells.pico)、
# 2〜4 を pico-build / pico-flash / pico-mon コマンドに置き換える。VsCode は使わない。
#
# このファイルが受け持つのは root 権限が必要な部分だけ:
#   - picotool / OpenOCD が Pico の USB デバイスに sudo なしで触れるための udev ルール
#   - シリアルポート (/dev/ttyACM*) を読み書きするためのグループ追加
{ config, lib, pkgs, ... }:

{
  # picotool は Pico を USB の生デバイスとして開く。BOOTSEL 中の RP2 ブートROM が
  # 見せる PICOBOOT インタフェース (マスストレージとは別のインタフェース) と、
  # 実行中プログラムの reset インタフェース (pico_stdio_usb) が対象。
  # nixpkgs の picotool は 60-picotool.rules を同梱しているのでそれを登録する。
  # openocd-rp2040 側のルールは Picoprobe/debugprobe 経由の SWD デバッグ用。
  services.udev.packages = [
    pkgs.picotool
    pkgs.openocd-rp2040
  ];

  # 上のルールは TAG+="uaccess" (ログイン中のユーザーに ACL を付与) と
  # GROUP="plugdev" を併記している。uaccess だけで用は足りるが、NixOS には
  # plugdev グループが存在しないため、放っておくと udev が毎回
  # 「Unknown group 'plugdev'」を吐く。グループを作って解消しておく。
  users.groups.plugdev = { };

  # dialout: Pico のシリアル (pico_stdio_usb) は /dev/ttyACM0 として現れ、
  #          root:dialout 660。手順書の「シリアルモニターの使い方」= pico-mon に必要。
  # plugdev: 上記のとおり picotool 用 udev ルールに合わせる。
  users.users.lemonade.extraGroups = [ "dialout" "plugdev" ];

  # 補足: BOOTSEL モードの Pico は USB マスストレージ (RPI-RP2) としても現れ、
  # udisks2 + udiskie が自動マウントする。picotool は別インタフェースを使うので
  # 干渉しない。手順書どおり .uf2 をドラッグ&ドロップして書き込む手も残るので、
  # 自動マウントはあえて無効化していない。
}
