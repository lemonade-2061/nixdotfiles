-- C/C++ の言語サーバ (clangd)。
--
-- RaspberryPi Pico 開発を VsCode なしで行うため、「C/C++ 拡張機能」の役割
-- (補完・定義ジャンプ・エラー表示) をここで担う。
-- clangd 本体は nix 側の devShell が提供する (~/nixos#pico の clang-tools)。
-- Mason は NixOS では使わない (lua/plugins/mason-disable.lua)。
--
-- 各プロジェクトには pico-new が .clangd を置いており、そこで
-- `CompilationDatabase: build` を指定しているので、cmake が build/ に出力した
-- compile_commands.json のフラグ (arm-none-eabi 向け -mcpu=cortex-m0plus など) が
-- そのまま使われる。
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          -- LazyVim 既定の cmd から --clang-tidy を外している。Pico SDK の
          -- ヘッダは clang-tidy の指摘が大量に出て実用にならないため。
          cmd = {
            "clangd",
            "--background-index",
            -- arm-none-eabi-gcc に組込みインクルードパスを問い合わせる許可。
            -- これが無いと clangd は newlib ではなくホストの glibc ヘッダを拾い、
            -- stdio.h → features.h → gnu/stubs.h の中で
            -- 「'gnu/stubs-32.h' file not found」になる (ARM は 32bit のため)。
            "--query-driver=*arm-none-eabi-*",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
          },
        },
      },
    },
  },
}
