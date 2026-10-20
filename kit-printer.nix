# KIT ネットワークプリンター (iogate3 / RICOH SP C840) モジュール
#
# 配布されている「Printer_setup_kit_64bit.zip」は Windows 専用
# (Setup.bat / RV_SETUP.exe / *.inf / *.cab) なので NixOS では使えない。
# ただし Setup.bat の中身を見ると、接続先は標準的な IPP over HTTP であり、
# サーバ (IIS) は Basic 認証も受け付けるため、CUPS から直接接続できる。
#
#   プリンター   : RICOH SP C840 JPN (A3カラー)
#   キュー名     : netpr01c
#   デバイス URI : http://iogate3.kanazawa-it.ac.jp/printers/netpr01c/.printer
#   認証         : ユーザー名 = 入学年度+学籍番号@kit-ad01.kanazawa-it.ac.jp
#                  パスワード = 和暦の生年月日 (例: 平成14年1月12日 -> h140112)
#   接続条件     : 学内LAN、または Remote-VPN (kit-vpn.nix) 接続下であること
#
# 印刷データを送った後、プリンター本体で学生証をかざしてログインし、
# 一覧から選んで「開始」を押すと出力される (印刷後のログアウト必須)。
#
# ※キューの登録コマンドはパスワードを含むので、この設定ファイルには書かない。
#   rebuild 後に手元で実行すること (手順は ~/nixos/kit-printer.md を参照)。

{ pkgs, ... }:

{
  services.printing = {
    enable = true;
    # SP C840 は PostScript3 / PCL を解釈する。Ricoh 純正 PPD は配布キットに
    # 含まれない (Windows 用 .inf のみ) ので、汎用 PPD 群を入れておく。
    drivers = with pkgs; [
      gutenprint
      gutenprintBin
      foomatic-db-ppds
    ];
  };

  # GUI でプリンターを追加・管理したい場合に使う (CLI だけなら不要)。
  environment.systemPackages = with pkgs; [ system-config-printer ];

  # lpadmin を sudo なしで叩けるようにする
  users.users.lemonade.extraGroups = [ "lp" ];
}
