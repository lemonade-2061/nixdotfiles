# KIT ネットワークプリンター (iogate3 / RICOH SP C840) を NixOS から使う

配布キット `Printer_setup_kit_64bit.zip` は Windows 専用（`Setup.bat` /
`RV_SETUP.exe` / `*.inf` / `*.cab`）なので、NixOS では使えない。
ただし `Setup.bat` を読むと接続先は標準的な **IPP over HTTP** で、
サーバ（IIS）は Basic 認証も受け付けるため、CUPS から直接繋げる。

| 項目 | 値 |
|---|---|
| プリンター | RICOH SP C840 JPN |
| キュー名 | `netpr01c` |
| デバイス URI | `http://iogate3.kanazawa-it.ac.jp/printers/netpr01c/.printer` |
| ユーザー名 | `入学年度+学籍番号@kit-ad01.kanazawa-it.ac.jp`（11桁+ドメイン） |
| パスワード | 和暦の生年月日（例: 平成14年1月12日 → `h140112`） |
| 接続条件 | 学内LAN または Remote-VPN（`kit-vpn.nix`）接続下 |

## 手順

### 1. CUPS を有効化（済）

`kit-printer.nix` を `configuration.nix` の imports に追加済み。反映する:

```sh
nrs            # = sudo nixos-rebuild switch --flake /home/lemonade/nixos#nixos
```

### 2. VPN を繋ぐ

学外からなら先に Remote-VPN を繋ぐこと。到達確認:

```sh
curl -sI http://iogate3.kanazawa-it.ac.jp/printers/netpr01c/.printer | head -1
# -> HTTP/1.1 401 Unauthorized が返れば到達している（401 は正常）
```

### 3. キューを登録

**パスワードを含むので、このコマンドは自分で打つこと**（設定ファイルには書かない）。
ユーザー名の `@` は URI の区切りとぶつかるので **`%40` に置き換える**。

```sh
sudo lpadmin -p netpr01c -E \
  -v 'http://20251502972%40kit-ad01.kanazawa-it.ac.jp:＜和暦生年月日＞@iogate3.kanazawa-it.ac.jp/printers/netpr01c/.printer' \
  -m drv:///sample.drv/generic.ppd \
  -D 'KIT netpr01c (RICOH SP C840)' \
  -o media=iso_a4_210x297mm -o sides=one-sided -o print-color-mode=monochrome
sudo lpadmin -d netpr01c          # 既定のプリンターにする
```

パスワードをディスクに置きたくない場合は、URI から `:＜パスワード＞` を外して
代わりに `-o auth-info-required=username,password` を付ける。この場合ジョブは
認証待ちで保留になり、都度入力が必要。

### 4. テスト印刷

```sh
lpstat -p -d                               # キューの状態
lp -d netpr01c ~/school/kakuritu/ensyu/w2/kadai_w02_print.pdf
lpstat -W not-completed -o                 # 送信済みジョブの確認
```

送信後、**プリンター本体で学生証をかざしてログイン** → 一覧から選んで「開始」。
**印刷後のログアウトは必須**（次の利用者がログインできなくなる）。

### 5. うまくいかないとき

- `lpstat -t` にエラーが出る / ジョブが消える
  → 認証失敗の可能性。ユーザー名の `%40`、パスワード（和暦）を見直す。
- プリンター本体の一覧にジョブが出てこない
  → ジョブの所有者が AD アカウントに紐付いていない。`-U 20251502972` を付けて
    `lp -U 20251502972 -d netpr01c ファイル` を試す。
- 文字化け・真っ白で出る
  → SP C840 が PostScript を解釈していない。PPD を変えて再試行:
    `lpinfo -m | grep -i ricoh` で候補を探すか、`-m drv:///sample.drv/generic.ppd`
    の代わりに PCL 系の PPD を指定する。
- CUPS の Web UI でも設定・確認できる: <http://localhost:631/>

### 5.1. 日本語PDFが途中でキャンセルされる（実際に踏んだ罠）

Chromium の「印刷 → PDFに保存」`--print-to-pdf` で作った日本語PDFは、CJK文字を
**Type 3 フォント**（1文字＝1個のPostScript手続き）として埋め込む。文字数が増えると
フォント定義が数百個になり、プリンタのPostScriptインタプリタがメモリを使い切って
ジョブを中断する。英数字だけのページは通るのに日本語ページだけ落ちる、という症状。

確認:

```sh
pdffonts -f 3 -l 3 file.pdf     # Type 3 が大量に並んでいたらこれ
```

対処 — 該当ページをラスタライズしてフォントを無くす:

```sh
gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfimage24 -r300 \
   -dPDFFitPage -sPAPERSIZE=a4 -o page_raster.pdf page.pdf
pdfunite 他のページ.pdf page_raster.pdf 出力.pdf
```

300dpi なら印刷品質は実質変わらない。まだ落ちるなら `-r200` に下げるか、
`-sDEVICE=pdfimage8`（グレースケール）にする。

### 6. 元に戻す

```sh
sudo lpadmin -x netpr01c                    # キュー削除
# configuration.nix の imports から ./kit-printer.nix を外して nrs
```
