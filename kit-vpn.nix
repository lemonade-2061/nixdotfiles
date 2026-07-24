# kit-vpn.nix — KIT Remote-VPN (Fortinet SSL-VPN) を openfortivpn で使うモジュール
#
# 使い方:
#   configuration.nix の imports に追加するだけ:
#     imports = [ ./kit-vpn.nix ];
#
# なぜ openfortivpn か:
#   - 公式FortiClientのLinux版は nixpkgs に無い(プロプライエタリ配布)
#   - openfortivpn は FortiGate の SSL-VPN プロトコル互換のOSS実装で、
#     KITのように「ユーザ名+パスワード認証・証明書なし」の構成ならこれで十分
#   - ppp ベースで tun デバイスを作るだけなので軽い

{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.openfortivpn ];

  # 接続設定を /etc/openfortivpn/kit として宣言的に配置する。
  # environment.etc を使う理由:
  #   設定ファイルも Nix 管理下に置けば、再インストールしても
  #   configuration.nix から丸ごと再現できる(NixOSの旨味)。
  environment.etc."openfortivpn/kit" = {
    text = ''
      host = ras2.kanazawa-it.ac.jp
      port = 10443
      username = a1502972
    '';
    # ⚠ username の aXXXXXXX は自分の「a + 学籍番号」に書き換えて。
    #
    # ⚠ password はここに書かないこと。
    #   Nixストア(/nix/store)は全ユーザーが読める world-readable なので、
    #   平文パスワードを .nix に書くとシステム全員に漏れる。
    #   接続時に毎回プロンプトで入力するのが一番安全。
    mode = "0644";
  };

  # openfortivpn は tun デバイスを作るため root 権限が要る。
  # 毎回 sudo でもいいけど、sudo ルールを絞っておくと
  # 「VPN接続コマンドだけはパスワード無しで実行可」にできて楽。
  # (不要ならこのブロックごと消してOK。その場合は普通に sudo で叩く)
  security.sudo.extraRules = [{
    users = [ "lemonade" ];   # ← 自分のNixOS上のユーザ名に変更
    commands = [{
      command = "${pkgs.openfortivpn}/bin/openfortivpn -c /etc/openfortivpn/kit";
      options = [ "NOPASSWD" ];
    }];
  }];
}
