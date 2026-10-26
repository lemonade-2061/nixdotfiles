# JetBrains 公式の Kotlin LSP (IntelliJ の解析エンジンを headless で動かすもの)。
# nixpkgs には kotlin-lsp がまだ無く、入っている kotlin-language-server (fwcd 製) は
# 開発が止まっているので、配布 tarball をここで固めている。
#
# 中身は JBR 同梱の prebuilt なので、やることは autoPatchelfHook でリンクを
# NixOS 向けに張り替えるだけ。GUI 用の .so は headless では読まれないので
# 依存が欠けていても良い (autoPatchelfIgnoreMissingDeps)。
#
# 更新するとき:
#   1. https://github.com/Kotlin/kotlin-lsp/releases で新しい版を確認して version を変更
#   2. nix build でハッシュ不一致のエラーに出る値を hash に貼る
{ lib
, stdenv
, stdenvNoCC
, fetchurl
, autoPatchelfHook
, runtimeShell
, zlib
, fontconfig
, freetype
, alsa-lib
, libGL
, libx11
, libxext
, libxi
, libxrender
, libxtst
, libxrandr
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "kotlin-lsp";
  version = "263.7084.0";

  src = fetchurl {
    url = "https://download.jetbrains.com/language-server/kotlin-server/${finalAttrs.version}/kotlin-server-${finalAttrs.version}.tar.gz";
    hash = "sha256-rgxLAeF6tzpKUienjqmebcvj5JlgAxWyJ1mk5M3dEd8=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    stdenv.cc.cc.lib   # libstdc++ / libgcc_s
    zlib
    fontconfig
    freetype
    alsa-lib
    libGL
    libx11
    libxext
    libxi
    libxrender
    libxtst
    libxrandr
  ];

  # 同梱 JBR には JCEF など GUI 専用の .so が入っていて依存が全部は揃わない。
  autoPatchelfIgnoreMissingDeps = true;

  dontConfigure = true;
  dontBuild = true;

  # Claude Code の kotlin-lsp プラグインは `kotlin-lsp --stdio` を叩くので、その名前で
  # 起動スクリプトを置く (本体は bin/intellij-server。kotlin-lsp.sh は deprecated)。
  # --system-path を渡さないと毎回 /tmp/idea-system<乱数> にインデックスを作り直すため、
  # cwd ごとに ~/.cache 以下へ固定して 2 回目以降の起動を速くする。プロジェクトを跨いだ
  # 同時起動でロックが衝突しないよう、キーは cwd から作っている。
  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/kotlin-lsp"
    cp -a . "$out/share/kotlin-lsp"

    install -Dm755 /dev/stdin "$out/bin/kotlin-lsp" <<WRAPPER
#!${runtimeShell}
: "\''${KOTLIN_LSP_SYSTEM_PATH:=\''${XDG_CACHE_HOME:-\$HOME/.cache}/kotlin-lsp/\''${PWD//\//_}}"
exec "$out/share/kotlin-lsp/bin/intellij-server" --system-path "\$KOTLIN_LSP_SYSTEM_PATH" "\$@"
WRAPPER

    runHook postInstall
  '';

  meta = {
    description = "Kotlin language server by JetBrains (IntelliJ-based)";
    homepage = "https://github.com/Kotlin/kotlin-lsp";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "kotlin-lsp";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
