-- NixOS では Mason の動的リンクバイナリが動かないため無効化。
-- LSP・フォーマッタ等は home.nix (nix 側) で管理する。
return {
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
}
