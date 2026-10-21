-- space+e (snacks explorer) をトグルではなく「行き帰り」できるようにする。
--
-- LazyVim 既定の <leader>e は Snacks.picker.pick() をそのまま呼ぶので、
-- 既に explorer が開いていると無条件で閉じてしまう。つまりコード編集中に
-- ツリーへ飛びたいとき「閉じる」→もう一度押して「開く」の 2 手になる。
--
-- ここでは状態で分岐する:
--   閉じている           → 開く (snacks 側が現在のファイルに合わせてくれる)
--   開いててフォーカス外 → フォーカスを移す + 今のファイルを reveal
--   explorer 上にいる    → 閉じる (従来どおりのトグル)

-- 名前付きの実ファイルを編集中か (無名バッファや terminal 等では reveal しない)
local function in_real_file()
	local buf = vim.api.nvim_get_current_buf()
	if vim.bo[buf].buftype ~= "" then
		return false
	end
	local name = vim.api.nvim_buf_get_name(buf)
	return name ~= "" and vim.uv.fs_stat(name) ~= nil
end

---@param opts? table Snacks.explorer に渡すオプション (cwd など)
local function explore(opts)
	-- get() は既定で現在のタブの picker だけを返す
	local picker = Snacks.picker.get({ source = "explorer" })[1]

	if not picker then
		return Snacks.explorer(opts)
	end

	if picker:is_focused() then
		picker:close()
		return
	end

	if in_real_file() then
		Snacks.explorer.reveal() -- カーソルを今開いているファイルの行に合わせる
	end
	picker:focus()
	return picker
end

return {
	{
		"folke/snacks.nvim",
		keys = {
			{
				"<leader>fe",
				function()
					explore({ cwd = LazyVim.root() })
				end,
				desc = "Explorer Snacks (root dir)",
			},
			{
				"<leader>fE",
				function()
					explore()
				end,
				desc = "Explorer Snacks (cwd)",
			},
			-- <leader>e / <leader>E は remap ではなく直接呼ぶ (上書きのため)
			{
				"<leader>e",
				function()
					explore({ cwd = LazyVim.root() })
				end,
				desc = "Explorer Snacks (root dir)",
			},
			{
				"<leader>E",
				function()
					explore()
				end,
				desc = "Explorer Snacks (cwd)",
			},
		},
	},
}
