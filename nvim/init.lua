vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set
local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO)
end

-- options
for k, v in pairs({
	number = true,
	relativenumber = true,
	cursorline = true,
	signcolumn = "yes",
	scrolloff = 8,
	wrap = false,

	expandtab = true,
	shiftwidth = 4,
	tabstop = 4,
	smartindent = true,

	ignorecase = true,
	smartcase = true,
	inccommand = "split",
	confirm = true,

	mouse = "a",
	clipboard = "unnamedplus",
	splitright = true,
	splitbelow = true,
	undofile = true,
	swapfile = false,
	updatetime = 250,
	timeoutlen = 400,

	wildmenu = true,
	wildmode = "noselect:lastused,full",
	wildoptions = "pum,fuzzy",
	wildignorecase = true,
}) do
	vim.opt[k] = v
end

vim.opt.path:append("**")
vim.opt.wildignore:append({ "*/.git/*", "*/node_modules/*", "*/build/*", "*.import" })

if vim.fn.executable("rg") == 1 then
	vim.opt.grepprg = "rg --vimgrep --smart-case"
	vim.opt.grepformat = "%f:%l:%c:%m"
end

-- colorscheme
vim.cmd.colorscheme("monochrome")

-- terminal
map("n", "<C-/>", "<cmd>term<cr>", { desc = "Open terminal" })
map("n", "<C-_>", "<cmd>term<cr>", { desc = "Open terminal" })
map("t", "<Esc><Esc>", [[<C-\><C-n>]])
for _, k in ipairs({ "h", "j", "k", "l" }) do
	map("t", "<C-w>" .. k, "<C-\\><C-n><C-w>" .. k, { silent = true })
end

--
map("n", "<Esc>", "<cmd>noh<cr>", { desc = "Clear highlights" })
map("n", "<C-s>", "<cmd>write<cr>", { desc = "Save file" })

--
map("n", "<M-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move line down" })
map("n", "<M-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move line up" })
map("x", "<M-j>", ":m '>+1<CR>gv=gv", { silent = true, desc = "Move selection down" })
map("x", "<M-k>", ":m '<-2<CR>gv=gv", { silent = true, desc = "Move selection up" })
map("x", "<", "<gv")
map("x", ">", ">gv")

--
map("n", "g[", function()
	local word = vim.fn.expand("<cword>")
	if word == "" then
		return
	end

	local tags = vim.fn.taglist("^" .. vim.fn.escape(word, "\\") .. "$")
	if #tags == 0 then
		return notify("No tags for " .. word, vim.log.levels.WARN)
	end

	local items = {}
	for _, t in ipairs(tags) do
		local num = tonumber(t.cmd)
		items[#items + 1] = {
			filename = t.filename,
			lnum = num or 1,
			pattern = (not num) and (t.cmd:gsub("^/", ""):gsub('/;?"?$', "")) or nil,
			text = (t.kind or "") .. " " .. t.name,
		}
	end

	vim.fn.setqflist({}, " ", { title = "tags: " .. word, items = items })
	vim.cmd.copen()
end, { desc = "Open tags in quickfix" })

-- buffers
map("n", "<leader>bn", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bp", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<S-h>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<S-l>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })

map("n", "<leader>bd", function()
	local buf = vim.api.nvim_get_current_buf()
	local alt = vim.fn.bufnr("#")

	local target = (alt > 0 and alt ~= buf and vim.fn.buflisted(alt) == 1) and alt or nil
	if not target then
		for _, b in ipairs(vim.api.nvim_list_bufs()) do
			if b ~= buf and vim.bo[b].buflisted then
				target = b
				break
			end
		end
	end

	for _, win in ipairs(vim.fn.win_findbuf(buf)) do
		vim.api.nvim_win_call(win, function()
			if target then
				vim.cmd.buffer(target)
			else
				vim.cmd.enew()
			end
		end)
	end

	pcall(vim.api.nvim_buf_delete, buf, {})
end, { desc = "Close buffer, keep split" })

map("n", "<leader>bo", function()
	local cur = vim.api.nvim_get_current_buf()
	local skipped = 0
	for _, b in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
		if b.bufnr ~= cur then
			if b.changed == 1 then
				skipped = skipped + 1
			else
				pcall(vim.api.nvim_buf_delete, b.bufnr, {})
			end
		end
	end
	if skipped > 0 then
		notify(skipped .. " modified buffer(s) were not closed", vim.log.levels.WARN)
	end
end, { desc = "Close other buffers" })

-- tabs
map("n", "<leader>tn", "<cmd>tabnext<cr>", { desc = "Next tab" })
map("n", "<leader>tp", "<cmd>tabprevious<cr>", { desc = "Previous tab" })
map("n", "<S-C-h>", "<cmd>tabnext<cr>", { desc = "Next tab" })
map("n", "<S-C-l>", "<cmd>tabprevious<cr>", { desc = "Previous tab" })
map("n", "<leader>td", "<cmd>tabclose<cr>", { desc = "Close tab" })

local default_markers = { "project.godot", ".git", "tags", "build.gradle.kts" }

local function project_root(markers, include_cwd)
	if include_cwd == nil then
		include_cwd = true
	end
	markers = markers or default_markers
	if type(markers) == "string" then
		markers = { markers }
	end
	return vim.fs.root(0, markers) or (include_cwd and vim.fn.getcwd() or nil)
end

-- Regen tags
vim.api.nvim_create_user_command("RegenTags", function()
	local root = project_root(nil, false)
	if not root then
		return notify("Root not found!", vim.log.levels.WARN)
	end
	vim.system(
		{
			"ctags",
			"-R",
			"--exclude=.git",
			"--exclude=.venv",
			"--exclude=node_modules",
			"--exclude=build",
			"--exclude=*.md",
			"-f",
			"tags",
			".",
		},
		{ cwd = root },
		vim.schedule_wrap(function(res)
			notify(
				res.code == 0 and "tags: done" or ("ctags failed: " .. (res.stderr or "")),
				res.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
			)
		end)
	)
end, { desc = "Regenerate CTAGS" })

-- autocmd
vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
	callback = function()
		vim.hl.on_yank({ higroup = "IncSearch", timeout = 150 })
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("QfKeys", { clear = true }),
	pattern = "qf",
	callback = function(ev)
		map("n", "q", "<cmd>cclose<cr>", { buffer = ev.buf, desc = "Close quickfix" })
	end,
})

vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.diagnostic.config({
	update_in_insert = false,
	severity_sort = true,
	virtual_text = true,
	float = { border = "single", source = true },
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspKeys", { clear = true }),
	callback = function(ev)
		map("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf, desc = "Definition" })
		map("n", "gD", vim.lsp.buf.declaration, { buffer = ev.buf, desc = "Declaration" })
		map("n", "<leader>cr", vim.lsp.buf.rename, { buffer = ev.buf, desc = "Rename symbol" })
	end,
})

vim.api.nvim_create_autocmd("PackChanged", {
	group = vim.api.nvim_create_augroup("UserPackChanged", { clear = true }),
	callback = function(ev)
		local d = ev.data
		if d.spec.name == "nvim-treesitter" and (d.kind == "install" or d.kind == "update") then
			if not d.active then
				vim.cmd.packadd("nvim-treesitter")
			end
			pcall(vim.cmd, "TSUpdate")
		end
	end,
})

local function gdck_root(path)
	return vim.fs.root(path, { "gdck.toml", ".gdck.toml" })
end

-- plugins
require("pack_list").pack_list({
	{
		"stevearc/oil.nvim",
		opts = {
			default_file_explorer = true,
			columns = { "permissions", "size", { "mtime", format = "%Y-%m-%d %H:%M" } },
			view_options = { show_hidden = true },
			skip_confirm_for_simple_edits = true,
			keymaps = { ["<C-s>"] = false, ["<C-l>"] = false, ["g,"] = "actions.refresh" },
		},
		config = function(oil)
			map("n", "<leader>e", function()
				if vim.bo.filetype == "oil" then
					oil.close()
				else
					oil.open(project_root())
				end
			end, { desc = "Explorer (project root)" })

			map("n", "<leader>E", function()
				if vim.bo.filetype == "oil" then
					oil.close()
				else
					oil.open()
				end
			end, { desc = "Explorer (current file)" })

			map("n", "-", "<cmd>Oil<cr>", { desc = "Parent directory" })
		end,
	},
	{
		"echasnovski/mini.pick",
		config = function(pick)
			vim.ui.select = pick.ui_select
			map("n", "<leader>ff", pick.builtin.files, { desc = "Find file" })
			map("n", "<leader><leader>", pick.builtin.files, { desc = "Find file" })
			map("n", "<leader>fg", pick.builtin.grep_live, { desc = "Live grep" })
			map("n", "<leader>fb", pick.builtin.buffers, { desc = "Buffers" })
			map("n", "<leader>fh", pick.builtin.help, { desc = "Help" })
		end,
	},
	{
		"echasnovski/mini.extra",
		config = function(extra)
			local lsp = extra.pickers.lsp
			map("n", "<leader>fr", function()
				lsp({ scope = "references" })
			end, { desc = "LSP references" })
			map("n", "<leader>fs", function()
				lsp({ scope = "document_symbol" })
			end, { desc = "Document symbols" })
			map("n", "<leader>fS", function()
				lsp({ scope = "workspace_symbol" })
			end, { desc = "Workspace symbols" })
			map("n", "<leader>fd", function()
				lsp({ scope = "definition" })
			end, { desc = "LSP definition" })
		end,
	},
	{
		"echasnovski/mini.surround",
		opts = {
			mappings = {
				add = "gs",
				delete = "ds",
				replace = "cs",
				find = "",
				find_left = "",
				highlight = "",
				update_n_lines = "",
			},
		},
	},
	{
		"echasnovski/mini.sessions",
		opts = {
			autoread = false,
			autowrite = true,
			file = "",
			directory = vim.fn.stdpath("data") .. "/sessions",
		},
		config = function(sessions)
			local function session_name()
				return (vim.fn.getcwd():gsub("[/\\:]", "%%"))
			end

			map("n", "<leader>sw", function()
				sessions.write(session_name())
			end, { desc = "Session: save" })
			map("n", "<leader>sr", function()
				sessions.select()
			end, { desc = "Session: pick" })
			map("n", "<leader>sd", function()
				sessions.select("delete")
			end, { desc = "Session: delete" })
		end,
	},
	{
		"echasnovski/mini.visits",
		config = function(visits)
			map("n", "<leader>fv", function()
				require("mini.extra").pickers.visit_paths()
			end, { desc = "Recent in project" })
		end,
	},
	{
		"echasnovski/mini.align",
		opts = {
			mappings = { start = "gl", start_with_preview = "gL" },
		},
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				gdscript = { "gdscript_formatter", "gdck", "gdformat", stop_after_first = true, lsp_format = "never" },
				kotlin = { "ktlint", lsp_format = "prefer" },
				sh = { "shfmt" },
			},
			formatters = {
				gdscript_formatter = {
					command = "gdscript-formatter",
					args = {},
					stdin = true,
					condition = function(_, ctx)
						return vim.fn.executable("gdscript-formatter")
					end,
					cwd = function(_, ctx)
						return project_root({ "project.godot" })
					end,
					exit_codes = { 0 },
				},
				gdck = {
					command = "gdck",
					args = { "format", "-" },
					stdin = true,
					condition = function(_, ctx)
						return gdck_root(ctx.dirname) ~= nil and vim.fn.executable("gdck")
					end,
					cwd = function(_, ctx)
						return gdck_root(ctx.dirname)
					end,
					exit_codes = { 0, 1 },
				},
			},
			default_format_opts = { lsp_format = "fallback" },
		},
		config = function(conform)
			map({ "n", "x" }, "<leader>cf", function()
				conform.format({ async = false })
			end, { desc = "Format buffer/selection" })
		end,
	},
	{
		"mfussenegger/nvim-lint",
		module = "lint",
		config = function(lint)
			lint.linters_by_ft = {
				lua = { "luacheck" },
				gdscript = { "gdlint" },
				sh = { "shellcheck" },
				kotlin = { "ktlint" },
			}

			map("n", "<leader>cc", function()
				lint.try_lint()
			end, { desc = "Lint file" })
		end,
	},
	{
		"neovim/nvim-lspconfig",
		module = false,
		config = function()
			vim.lsp.enable({ "lua_ls", "gdscript", "gdck", "kotlin_lsp", "bashls" })
			vim.lsp.config("lua_ls", {
				settings = { Lua = { runtime = { version = "LuaJIT" } } },
			})
			vim.lsp.config("kotlin_lsp", {
				cmd = { vim.fn.expand("~/.local/bin/kotlin-lsp"), "--stdio" },
			})
			vim.lsp.config("gdck", {
				cmd = { "gdck", "lsp" },
				filetypes = { "gdscript" },
				root_dir = function(bufnr, on_dir)
					local root = gdck_root(bufnr)
					if root then
						on_dir(root)
					end
				end,
			})
		end,
	},
	{
		"tpope/vim-fugitive",
		module = false,
		config = function()
			map("n", "<leader>gg", "<cmd>Git<cr>", { desc = "Git status" })
			map("n", "<leader>gb", "<cmd>Git blame<cr>", { desc = "Git blame" })
			map("n", "<leader>gd", "<cmd>Gdiffsplit<cr>", { desc = "Git diff" })
		end,
	},
	{
		"folke/which-key.nvim",
		module = "which-key",
		opts = {
			delay = 300,
			icons = { mappings = false },
			win = { border = "single" },
		},
		config = function(wk)
			wk.add({
				{ "<leader>b", group = "buffers" },
				{ "<leader>c", group = "code" },
				{ "<leader>f", group = "find" },
				{ "<leader>l", group = "lua funcs", mode = { "n", "x" } },
				{ "<leader>p", group = "overseer" },
				{ "<leader>s", group = "session" },
				{ "<leader>g", group = "git" },
			})

			map("n", "<leader>?", function()
				wk.show({ global = false })
			end, { desc = "Buffer keymaps" })
		end,
	},
	{
		"stevearc/overseer.nvim",
		opts = {
			templates = { "builtin", "godot" },
			task_list = { direction = "bottom", min_height = 10 },
		},
		config = function(overseer)
			map("n", "<leader>pr", "<cmd>OverseerRun<cr>", { desc = "Run task" })
			map("n", "<leader>pt", "<cmd>OverseerToggle<cr>", { desc = "Task list" })
			map("n", "<leader>pa", "<cmd>OverseerTaskAction<cr>", { desc = "Task action" })
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		version = "main",
		config = function(ts)
			ts.install({
				"gdscript",
				"kotlin",
				"python",
				"bash",
				"lua",
				"vim",
				"vimdoc",
				"markdown",
				"markdown_inline",
				"json",
				"yaml",
				"toml",
			})

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
				callback = function(ev)
					if not pcall(vim.treesitter.start, ev.buf) then
						return
					end
					local win = vim.fn.bufwinid(ev.buf)
					if win ~= -1 then
						vim.wo[win][0].foldmethod = "expr"
						vim.wo[win][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
						vim.wo[win][0].foldlevel = 99
					end
				end,
			})
		end,
	},
	{
		"saghen/blink.cmp",
		version = vim.version.range("1.*"),
		opts = { keymap = { preset = "default" }, signature = { enabled = true } },
	},
})

-- custom
require("userfuncs").setup()
require("compile").setup({
	efm_by_cmd = {
		godot = "%f:%l - %m,%EParse Error: %m,%Z%.%#at: %f:%l,%m",
		gradle = "e: file://%f:%l:%c %m,e: %f: (%l\\, %c): %m,w: %f: (%l\\, %c): %m",
		cargo = "%-G%\\s%#Compiling%.%#,%Eerror%.%#: %m,%Z%\\s%#--> %f:%l:%c,%-G%.%#",
		python = '%C %.%#,%A  File "%f"\\, line %l%.%#,%Z%[%^ ]%\\@=%m',
		gcc = "%f:%l:%c: %trror: %m,%f:%l:%c: %tarning: %m,%f:%l: %m",
	},
})
map("n", "<leader>cb", "<cmd>Compile<cr>", { desc = "Compile" })
map("n", "<leader>cB", "<cmd>Compile!<cr>", { desc = "Recompile" })
map("n", "<leader>cx", "<cmd>CompileStop<cr>", { desc = "Stop compile" })
map("n", "<leader>q", "<cmd>lua require('compile').toggle()<cr>", { desc = "Toggle quickfix" })
require("hex").setup()
map("n", "<leader>xh", require("hex").toggle, { desc = "Toggle hex view" })
