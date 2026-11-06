local M = {}

M.funcs = {}
M.path = vim.fn.stdpath("data") .. "/userfuncs.lua"

local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = "userfuncs" })
end

-- Storage: blocks "-- >>> name[,name]*" ... "-- <<<"
-- Code outside the markers is ignored and lost on the next rewrite.
local function read_blocks()
	local blocks, cur = {}, nil
	if vim.fn.filereadable(M.path) == 0 then
		return blocks
	end
	for _, line in ipairs(vim.fn.readfile(M.path)) do
		local names = line:match("^%-%- >>> (.+)$")
		if names then
			cur = { names = vim.split(names, ",", { plain = true }), lines = {} }
		elseif line == "-- <<<" then
			if cur then
				cur.src = table.concat(cur.lines, "\n")
				blocks[#blocks + 1] = cur
				cur = nil
			end
		elseif cur then
			cur.lines[#cur.lines + 1] = line
		end
	end
	return blocks
end

local function write_blocks(blocks)
	local out = {}
	for _, b in ipairs(blocks) do
		out[#out + 1] = "-- >>> " .. table.concat(b.names, ",")
		vim.list_extend(out, vim.split(b.src, "\n", { plain = true }))
		out[#out + 1] = "-- <<<"
		out[#out + 1] = ""
	end
	vim.fn.writefile(out, M.path)
end

-- Compile a chunk in a sandboxed env that falls back to _G.
-- Global functions whose names do not start with "_" become commands;
-- local functions stay private helpers of the block.
local function compile(src)
	local env = setmetatable({}, { __index = _G })
	local chunk, err = load(src, "=userfunc", "t", env)
	if not chunk then
		return nil, err
	end
	local ok, e = pcall(chunk)
	if not ok then
		return nil, e
	end
	local fns = {}
	for k, v in pairs(env) do
		if type(v) == "function" and type(k) == "string" and k:sub(1, 1) ~= "_" then
			fns[k] = v
		end
	end
	return fns
end

function M.names()
	local t = vim.tbl_keys(M.funcs)
	table.sort(t)
	return t
end

function M.reload()
	M.funcs = {}
	for _, b in ipairs(read_blocks()) do
		local fns, err = compile(b.src)
		if fns then
			for n, f in pairs(fns) do
				M.funcs[n] = f
			end
		else
			notify("Error in block " .. table.concat(b.names, ",") .. ": " .. err, vim.log.levels.ERROR)
		end
	end
end

-- Removes the whole block that defines `name` (all its functions go with it)
function M.undef(name)
	local kept, removed = {}, nil
	for _, b in ipairs(read_blocks()) do
		if vim.tbl_contains(b.names, name) then
			removed = b
		else
			kept[#kept + 1] = b
		end
	end
	if not removed then
		return notify("Function not found: " .. name, vim.log.levels.WARN)
	end
	write_blocks(kept)
	M.reload()
	notify("Removed: " .. table.concat(removed.names, ", "))
end

function M.prompt_undef()
	local names = M.names()
	if #names == 0 then
		return notify("No saved functions", vim.log.levels.WARN)
	end

	-- name -> all names in the same block (shown so it is clear what goes together)
	local group = {}
	for _, b in ipairs(read_blocks()) do
		for _, n in ipairs(b.names) do
			group[n] = table.concat(b.names, ",")
		end
	end

	vim.ui.select(names, {
		prompt = "Remove function",
		format_item = function(n)
			return group[n] and group[n] ~= n and (n .. "  [" .. group[n] .. "]") or n
		end,
	}, function(name)
		if name and vim.fn.confirm("Remove block with " .. name .. "?", "&Yes\n&No", 2) == 1 then
			M.undef(name)
		end
	end)
end

function M.define(src)
	local fns, err = compile(src)
	if not fns then
		return notify(err, vim.log.levels.ERROR)
	end
	local names = vim.tbl_keys(fns)
	table.sort(names)
	if #names == 0 then
		return notify("No global functions found (e.g. function name(ctx) ... end)", vim.log.levels.WARN)
	end
	-- drop old blocks that define any of the same names
	local kept = {}
	for _, b in ipairs(read_blocks()) do
		local clash = false
		for _, n in ipairs(b.names) do
			if fns[n] then
				clash = true
			end
		end
		if not clash then
			kept[#kept + 1] = b
		end
	end
	kept[#kept + 1] = { names = names, src = src }
	write_blocks(kept)
	for n, f in pairs(fns) do
		M.funcs[n] = f
	end
	notify("Saved: " .. table.concat(names, ", "))
end

-- Input: whole buffer / whole lines / exact characters
local function read_input(buf, input)
	if input.kind == "buffer" then
		return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	elseif input.kind == "lines" then
		return vim.api.nvim_buf_get_lines(buf, input.l1 - 1, input.l2, false)
	end
	return vim.api.nvim_buf_get_text(buf, input.l1 - 1, input.c1, input.l2 - 1, input.c2, {})
end

local function replace(buf, input, res)
	local lines = type(res) == "table" and res or vim.split(tostring(res), "\n", { plain = true })
	if input.kind == "buffer" then
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	elseif input.kind == "lines" then
		vim.api.nvim_buf_set_lines(buf, input.l1 - 1, input.l2, false, lines)
	else
		vim.api.nvim_buf_set_text(buf, input.l1 - 1, input.c1, input.l2 - 1, input.c2, lines)
	end
end

-- Reads the last visual selection. Requires '< and '> to be up to date,
-- so callers leave visual mode first.
local function capture_visual(buf)
	local mode = vim.fn.visualmode()
	local s, e = vim.fn.getpos("'<"), vim.fn.getpos("'>")
	if mode ~= "v" then -- linewise and blockwise selections are treated as whole lines
		return { kind = "lines", l1 = s[2], l2 = e[2] }
	end
	local last = vim.api.nvim_buf_get_lines(buf, e[2] - 1, e[2], false)[1] or ""
	local c2 = math.min(e[3], #last)
	if c2 > 0 then
		c2 = c2 + vim.str_utf_end(last, c2) -- extend to the end of a multibyte character
	end
	return { kind = "chars", l1 = s[2], c1 = s[3] - 1, l2 = e[2], c2 = c2 }
end

-- Current buffer, window and input (whole buffer or last selection)
local function target(visual)
	local buf = vim.api.nvim_get_current_buf()
	return buf, vim.api.nvim_get_current_win(), visual and capture_visual(buf) or { kind = "buffer" }
end

-- Input for Ex commands with a range. A range equal to the last charwise
-- selection keeps exact columns; any other range is whole lines.
local function range_input(o)
	if o.range == 0 then
		return { kind = "buffer" }
	end
	local s, e = vim.fn.getpos("'<"), vim.fn.getpos("'>")
	if o.line1 == s[2] and o.line2 == e[2] and vim.fn.visualmode() == "v" then
		return capture_visual(vim.api.nvim_get_current_buf())
	end
	return { kind = "lines", l1 = o.line1, l2 = o.line2 }
end

-- Puts the result into the unnamed and system clipboard registers
local function to_clipboard(res)
	local text = type(res) == "table" and table.concat(res, "\n") or tostring(res)
	vim.fn.setreg('"', text) -- unnamed register: paste with p
	pcall(vim.fn.setreg, "+", text) -- system clipboard, if a provider exists
	local preview = vim.fn.strcharpart((text:gsub("\n", "⏎")), 0, 60)
	notify(("Copied (%d chars): %s"):format(#text, preview))
end

-- "{a = 55}" -> { a = 55 }. The environment is empty, so only literals are
-- allowed (no vim, no global functions). Returns nil if it is not a valid value.
local function parse_data(argstr)
	if vim.trim(argstr) == "" then
		return nil
	end
	local chunk = load("return " .. argstr, "=args", "t", {})
	if not chunk then
		return nil
	end
	local ok, val = pcall(chunk)
	return ok and val or nil
end

-- Context passed to functions
local function make_ctx(argstr, input, buf, win)
	local lines = input and read_input(buf, input) or {}
	local ctx = {
		text = table.concat(lines, "\n"),
		lines = lines,
		argstr = argstr, -- raw argument string
		args = vim.split(argstr, "%s+", { trimempty = true }), -- arguments split by whitespace
		kind = input and input.kind or "none", -- "buffer" | "lines" | "chars" | "none"
		buf = buf,
		win = win,
		-- insert text at the cursor
		insert = function(text)
			vim.api.nvim_win_call(win, function()
				vim.api.nvim_put(vim.split(text, "\n", { plain = true }), "c", false, true)
			end)
		end,
		-- replace the input text explicitly (no-op when there is no input)
		replace = function(text)
			if input then
				replace(buf, input, text)
			end
		end,
		-- put text into the clipboard registers; the buffer is not modified
		copy = function(text)
			to_clipboard(text)
		end,
	}
	-- ctx.data (parsed literal from the arguments) is computed on first access
	return setmetatable(ctx, {
		__index = function(t, k)
			if k == "data" then
				local v = parse_data(argstr)
				rawset(t, "data", v)
				return v
			end
		end,
	})
end

-- Run a saved function; a returned value replaces the input text
local function run(name, argstr, input, buf, win)
	local fn = M.funcs[name]
	if not fn then
		return notify("Function not found: " .. name, vim.log.levels.ERROR)
	end
	local ok, res = pcall(fn, make_ctx(argstr, input, buf, win))
	if not ok then
		return notify(name .. ": " .. tostring(res), vim.log.levels.ERROR)
	end
	if res ~= nil then
		replace(buf, input, res)
	end
end

-- One-off execution: nothing is saved, the result goes to the clipboard registers
function M.eval(src, argstr, input, buf, win)
	local ctx = make_ctx(argstr, input, buf, win)
	local env = setmetatable({ ctx = ctx }, { __index = _G })

	-- try as an expression first, then as a block of statements
	local chunk = load("return " .. src, "=eval", "t", env)
	if not chunk then
		local err
		chunk, err = load(src, "=eval", "t", env)
		if not chunk then
			return notify(err, vim.log.levels.ERROR)
		end
	end

	local ok, res = pcall(chunk)
	if not ok then
		return notify(tostring(res), vim.log.levels.ERROR)
	end

	-- the code defined function(s) and returned nothing: call main or the only one
	if res == nil then
		local fn = type(env.main) == "function" and env.main or nil
		if not fn then
			local found = {}
			for _, v in pairs(env) do
				if type(v) == "function" then
					found[#found + 1] = v
				end
			end
			fn = #found == 1 and found[1] or nil
		end
		if fn then
			ok, res = pcall(fn, ctx)
			if not ok then
				return notify(tostring(res), vim.log.levels.ERROR)
			end
		end
	end

	if res ~= nil then
		to_clipboard(res)
	end
end

-- Interactive input
local function match_names(lead)
	return vim.tbl_filter(function(n)
		return vim.startswith(n, lead)
	end, M.names())
end

-- Pick a function and run it. With no_args the argument prompt is skipped.
function M.prompt(visual, no_args)
	if #M.names() == 0 then
		return notify("No saved functions (save with <leader>ld)", vim.log.levels.WARN)
	end
	local buf, win, input = target(visual)

	vim.ui.select(M.names(), { prompt = "Function" }, function(name)
		if not name then
			return
		end
		if no_args then
			return run(name, "", input, buf, win)
		end
		vim.ui.input({ prompt = name .. " args: " }, function(a)
			run(name, a or "", input, buf, win)
		end)
	end)
end

function M.prompt_eval(visual)
	local buf, win, input = target(visual)
	vim.ui.input({ prompt = "Lua: " }, function(code)
		if code and vim.trim(code) ~= "" then
			M.eval(code, "", input, buf, win)
		end
	end)
end

-- Commands and mappings
function M.setup()
	M.reload()

	local cmd = vim.api.nvim_create_user_command

	cmd("LuaDef", function(o)
		local lines = o.range > 0 and vim.api.nvim_buf_get_lines(0, o.line1 - 1, o.line2, false)
			or vim.api.nvim_buf_get_lines(0, 0, -1, false)
		M.define(table.concat(lines, "\n"))
	end, { range = true, desc = "Save functions from the range or the whole buffer" })

	cmd("LuaRun", function(o)
		local name, rest = o.args:match("^(%S+)%s*(.*)$")
		run(name, rest, range_input(o), vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win())
	end, {
		nargs = "+",
		range = true,
		desc = "Run a saved function: :LuaRun name args",
		complete = function(lead, line)
			return line:match("^%S+%s+%S*$") and match_names(lead) or {}
		end,
	})

	cmd("LuaEval", function(o)
		local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
		if o.args ~= "" then
			-- code is in the argument; the range (or whole buffer) is the input text
			M.eval(o.args, "", range_input(o), buf, win)
		else
			-- code is in the range/buffer itself; there is no input text
			local lines = o.range > 0 and vim.api.nvim_buf_get_lines(buf, o.line1 - 1, o.line2, false)
				or vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			M.eval(table.concat(lines, "\n"), "", nil, buf, win)
		end
	end, { nargs = "*", range = true, desc = "Run Lua once, result goes to the clipboard" })

	cmd("LuaUndef", function(o)
		if o.args == "" then
			M.prompt_undef()
		else
			M.undef(o.args)
		end
	end, {
		nargs = "?",
		desc = "Remove a saved function (picker if no name given)",
		complete = function(lead)
			return match_names(lead)
		end,
	})

	cmd("LuaFuncsEdit", function()
		vim.cmd.edit(M.path)
	end, { desc = "Open the saved functions file" })

	cmd("LuaFuncsReload", function()
		M.reload()
		notify("Reloaded: " .. #M.names() .. " functions")
	end, { desc = "Reload the saved functions file" })

	-- manual edits of the functions file are applied on save
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = vim.api.nvim_create_augroup("UserFuncsReload", { clear = true }),
		pattern = M.path,
		callback = function()
			M.reload()
		end,
	})

	local map = vim.keymap.set
	map("n", "<leader>lr", function()
		M.prompt(false)
	end, { desc = "Run user Lua func (buffer)" })
	map("x", "<leader>lr", function()
		vim.cmd("normal! \27") -- leave visual mode so '< and '> are updated
		M.prompt(true)
	end, { desc = "Run user Lua func (selection)" })

	map("n", "<leader>lR", function()
		M.prompt(false, true)
	end, { desc = "Run user Lua func (buffer, no args)" })
	map("x", "<leader>lR", function()
		vim.cmd("normal! \27")
		M.prompt(true, true)
	end, { desc = "Run user Lua func (selection, no args)" })

	map({ "n", "x" }, "<leader>ld", ":LuaDef<CR>", { desc = "Save Lua funcs from buffer/selection" })
	map("n", "<leader>lx", M.prompt_undef, { desc = "Delete user Lua func" })

	map("n", "<leader>le", function()
		M.prompt_eval(false)
	end, { desc = "Eval Lua (buffer) -> clipboard" })
	map("x", "<leader>le", function()
		vim.cmd("normal! \27")
		M.prompt_eval(true)
	end, { desc = "Eval Lua (selection) -> clipboard" })

	map({ "n", "x" }, "<leader>lE", ":LuaEval<CR>", { desc = "Run Lua from buffer/selection -> clipboard" })
end

return M
