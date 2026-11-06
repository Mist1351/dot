local M = {}

local SCHEME = "hex://"

-- Layout of a default xxd line (16 bytes per line, groups of 2 bytes):
--   "00000000: 4865 6c6c 6f20 776f 726c 6421 0a0a 0a0a  Hello world!...."
-- 0-based columns: hex digits start at 10, the ASCII column starts at 51.
local HEX_START = 10
local HEX_END = 49 -- exclusive
local ASCII_START = 51

local ns = vim.api.nvim_create_namespace("hex_cursor")
local MC_NS = vim.api.nvim_create_namespace("nvim.multicursor") -- built-in multicursor extmarks

local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = "hex" })
end

local function to_path(name)
	return (name:gsub("^hex://", ""))
end

-- Merge edits made in the ASCII column into the hex column of each line.
-- Only printable ASCII (0x20-0x7e) is applied; "." means "unchanged",
-- so a byte cannot be changed to 0x2e through the ASCII column.
local function sync_ascii(lines)
	local out = {}
	for i, l in ipairs(lines) do
		if not l:match("^%x+:") then
			out[i] = l
		else
			local head = l:sub(1, HEX_START) -- "00000000: "
			local hex = l:sub(HEX_START + 1, HEX_END)
			local ascii = l:sub(ASCII_START + 1)

			local bytes = {}
			for b in hex:gmatch("%x%x") do
				bytes[#bytes + 1] = b
			end

			for k, b in ipairs(bytes) do
				local n = tonumber(b, 16)
				local expected = (n >= 0x20 and n <= 0x7e) and string.char(n) or "."
				local actual = ascii:sub(k, k)
				if actual ~= "" and actual ~= "." and actual ~= expected then
					local code = actual:byte()
					if code >= 0x20 and code <= 0x7e then
						bytes[k] = ("%02x"):format(code)
					end
				end
			end

			local parts = {}
			for k = 1, #bytes, 2 do
				parts[#parts + 1] = bytes[k] .. (bytes[k + 1] or "")
			end
			-- keep the original padding and the ASCII column untouched
			local hex_new = table.concat(parts, " ")
			hex_new = hex_new .. string.rep(" ", math.max(0, (HEX_END - HEX_START) - #hex_new))
			out[i] = head .. hex_new .. l:sub(HEX_END + 1)
		end
	end
	return out
end

-- Rebuild the ASCII column from the hex column of one line
local function sync_hex(line)
	if not line:match("^%x+:") then
		return line
	end
	local hex = line:sub(HEX_START + 1, HEX_END):gsub("%s", "")
	local chars = {}
	for b in hex:gmatch("%x%x") do
		local n = tonumber(b, 16)
		chars[#chars + 1] = (n >= 0x20 and n <= 0x7e) and string.char(n) or "."
	end
	-- keep everything before the ASCII column, replace the column itself
	return line:sub(1, ASCII_START) .. table.concat(chars)
end

-- Highlight the byte under the cursor in both the hex and the ASCII column
local function highlight_cursor(buf)
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
	if not line:match("^%x+:") then
		return
	end

	local k -- 0-based byte index within the line
	if col >= ASCII_START then
		k = col - ASCII_START
	elseif col >= HEX_START and col < HEX_END then
		local off = col - HEX_START
		local within = off % 5 -- each 2-byte group takes 5 columns: "4865 "
		if within >= 4 then
			return -- on the separating space
		end
		k = math.floor(off / 5) * 2 + math.floor(within / 2)
	else
		return
	end
	if k > 15 then
		return
	end

	local hex_col = HEX_START + k * 2 + math.floor(k / 2)
	local hex_text = line:sub(hex_col + 1, hex_col + 2)
	if not hex_text:match("^%x%x$") then
		return -- past the last byte of a short line
	end

	local opts = { hl_group = "Visual", priority = 200 }
	vim.api.nvim_buf_set_extmark(buf, ns, row - 1, hex_col, vim.tbl_extend("force", opts, { end_col = hex_col + 2 }))
	if ASCII_START + k < #line then
		vim.api.nvim_buf_set_extmark(
			buf,
			ns,
			row - 1,
			ASCII_START + k,
			vim.tbl_extend("force", opts, { end_col = ASCII_START + k + 1 })
		)
	end
end

-- 0-based byte index (0..15) for a cursor column; nil in the offset column
local function byte_index(col)
	if col >= ASCII_START then
		return col - ASCII_START
	elseif col >= HEX_START and col < HEX_END then
		local off = col - HEX_START
		local group, within = math.floor(off / 5), off % 5
		if within >= 4 then
			return group * 2 + 1 -- on the space after a group: snap to the previous byte
		end
		return group * 2 + math.floor(within / 2)
	end
	return nil
end

-- Jump between the hex digits of a byte and its character in the ASCII column
local function jump_pair(buf)
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
	if not line:match("^%x+:") then
		return
	end

	local target
	if col >= ASCII_START then
		local k = math.min(col - ASCII_START, 15)
		target = HEX_START + k * 2 + math.floor(k / 2)
	else
		local k = byte_index(col) or 0
		-- clamp to the last character on a short final line
		target = math.min(ASCII_START + k, math.max(#line - 1, ASCII_START))
	end

	pcall(vim.api.nvim_win_set_cursor, 0, { row, target })
end

-- Keep both columns consistent after an edit on the current line.
-- The direction is chosen by the cursor column: an edit in the ASCII column
-- updates hex, an edit in the hex column updates ASCII. After the rewrite the
-- columns match, so a second run changes nothing; `syncing` guards re-entrance.
local syncing = false

local function sync_line(buf)
	if syncing then
		return
	end
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
	if not line then
		return
	end

	local new
	if col >= ASCII_START then
		new = sync_ascii({ line })[1]
	elseif col >= HEX_START then
		new = sync_hex(line)
	else
		return
	end

	if new ~= line then
		syncing = true
		pcall(vim.cmd, "undojoin") -- try to make it one undo step with the user edit
		vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { new })
		pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
		syncing = false
	end
end

-- Block and structural edits break the fixed xxd layout, so disable them.
-- Only replace-style edits (r, R) are left.
local function lock_layout(buf)
	local function off(mode, keys)
		for _, k in ipairs(keys) do
			vim.keymap.set(mode, k, "<Nop>", { buffer = buf, nowait = true })
		end
	end

	-- blockwise selection: the source of multi-line insert
	off({ "n", "x" }, { "<C-v>" })
	off("x", { "I", "A", "c", "C", "s", "S", "o", "O" })

	-- insert-mode entry points and deletions that shift columns
	off("n", { "i", "a", "I", "A", "o", "O", "s", "S", "c", "C", "x", "X", "p", "P", "J", "dd", "D" })
end

local function clear_cursors(buf)
	vim.api.nvim_buf_clear_namespace(buf, MC_NS, 0, -1)
end

-- Built-in multicursor edits would bypass sync_line (it only handles the
-- primary cursor), so cursor creation is disabled in hex buffers.
local function lock_multicursor(buf)
	local function off(mode, keys)
		for _, k in ipairs(keys) do
			vim.keymap.set(mode, k, "<Nop>", { buffer = buf, nowait = true })
		end
	end
	off({ "n", "x" }, { "Q", "zq" })
	off("n", { "gQ", "<C-LeftMouse>" })
	clear_cursors(buf)
end

-- Fill the buffer with `xxd` output of the real file
local function load(buf, path)
	if vim.fn.executable("xxd") == 0 then
		return notify("xxd is not installed", vim.log.levels.ERROR)
	end
	local res = vim.system({ "xxd", path }, { text = true }):wait()
	if res.code ~= 0 then
		return notify(res.stderr or "xxd failed", vim.log.levels.ERROR)
	end
	local lines = vim.split(res.stdout, "\n", { plain = true, trimempty = true })
	vim.bo[buf].buftype = "acwrite" -- :w triggers BufWriteCmd
	vim.bo[buf].swapfile = false
	vim.bo[buf].bufhidden = "wipe" -- one-shot: reopening always reads the file again
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].filetype = "xxd"
	vim.bo[buf].modified = false

	local group = vim.api.nvim_create_augroup("HexBuf" .. buf, { clear = true })
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		group = group,
		buffer = buf,
		callback = function()
			highlight_cursor(buf)
		end,
	})
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = group,
		buffer = buf,
		callback = function()
			clear_cursors(buf) -- safety net: drop any multicursors that appeared anyway
			sync_line(buf)
			highlight_cursor(buf)
		end,
	})
	highlight_cursor(buf)
	lock_layout(buf)
	lock_multicursor(buf)
    vim.keymap.set("n", "<Tab>", function()
        jump_pair(buf)
    end, { buffer = buf, nowait = true, desc = "Jump between hex and ASCII" })
end

-- Convert the text back to bytes and write them to the real file.
-- The columns are kept consistent while editing, so the hex column is the source.
local function save(buf, path)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local res = vim.system({ "xxd", "-r" }, { stdin = table.concat(lines, "\n") .. "\n" }):wait()
	if res.code ~= 0 then
		return notify(res.stderr or "xxd -r failed", vim.log.levels.ERROR)
	end
	local f, err = io.open(path, "wb")
	if not f then
		return notify("Cannot write " .. path .. ": " .. tostring(err), vim.log.levels.ERROR)
	end
	f:write(res.stdout)
	f:close()
	vim.bo[buf].modified = false
	notify("Written " .. #res.stdout .. " bytes to " .. vim.fn.fnamemodify(path, ":~"))
end

-- Open `file` (default: current buffer's file) in a hex buffer
function M.open(file)
	file = file ~= nil and file ~= "" and file or vim.api.nvim_buf_get_name(0)
	if file == "" or vim.startswith(file, SCHEME) then
		return notify("No file to show", vim.log.levels.WARN)
	end
	-- the hex view reads the file from disk, so save pending edits first
	if vim.bo.modified and vim.bo.buftype == "" then
		vim.cmd("silent write")
	end
	vim.cmd.edit(vim.fn.fnameescape(SCHEME .. vim.fn.fnamemodify(file, ":p")))
end

-- Toggle between the real file and its hex view
function M.toggle()
	local name = vim.api.nvim_buf_get_name(0)
	if vim.startswith(name, SCHEME) then
		vim.cmd.edit(vim.fn.fnameescape(to_path(name)))
	else
		M.open(name)
	end
end

function M.setup()
	local aug = vim.api.nvim_create_augroup("HexScheme", { clear = true })

	vim.api.nvim_create_autocmd("BufReadCmd", {
		group = aug,
		pattern = SCHEME .. "*",
		callback = function(ev)
			load(ev.buf, to_path(ev.match))
		end,
	})

	vim.api.nvim_create_autocmd("BufWriteCmd", {
		group = aug,
		pattern = SCHEME .. "*",
		callback = function(ev)
			save(ev.buf, to_path(ev.match))
		end,
	})

	vim.api.nvim_create_user_command("Hex", function(o)
		M.open(o.args)
	end, { nargs = "?", complete = "file", desc = "Open a file in hex view" })

	vim.api.nvim_create_user_command("HexToggle", M.toggle, { desc = "Toggle hex view of the current file" })
end

return M
