local M = {}

local config = {
	efm = nil, -- nil = vim.o.errorformat
	efm_by_cmd = {}, -- first word of the command (basename) -> errorformat
	height = 12, -- quickfix window height
	focus = false, -- true: move the cursor to quickfix on start
	jump_first = false, -- true: jump to the first entry when the command fails
	flush_ms = 50, -- how often accumulated output is flushed into the list
	close_on_success = true, -- close quickfix 1s after a successful run
}

local last_cmds = {} -- last command per working directory
local last_cmd
local current_cmd -- command of the running or last job, used to pick efm
local job, qf_id
local queue, pending, scheduled = {}, { stdout = "", stderr = "" }, false

-- errorformat for the current command: per-command, then global, then default
local function efm()
	if current_cmd then
		local first = current_cmd:match("^%s*(%S+)")
		first = first and vim.fn.fnamemodify(first, ":t")
		if first and config.efm_by_cmd[first] then
			return config.efm_by_cmd[first]
		end
	end
	return config.efm or vim.o.errorformat
end

-- window showing our list (0 if none)
local function qf_win()
	if not qf_id then
		return 0
	end
	return vim.fn.getqflist({ id = qf_id, winid = 0 }).winid
end

-- strip \r and ANSI escape sequences so text and efm match cleanly
local function clean(lines)
	return vim.tbl_map(function(l)
		return (l:gsub("\r", ""):gsub("\27%[[%d;?]*[%a]", ""))
	end, lines)
end

-- append queued lines to our list (by id, so other lists are not touched)
local function flush_queue()
	scheduled = false
	if #queue == 0 or not qf_id then
		return
	end
	local lines = queue
	queue = {}
	if vim.fn.getqflist({ id = qf_id }).id == 0 then
		return -- list was evicted or deleted
	end
	vim.fn.setqflist({}, "a", { id = qf_id, lines = lines, efm = efm() })

	-- follow the tail unless the cursor is inside the quickfix window
	local win = qf_win()
	if win ~= 0 and win ~= vim.api.nvim_get_current_win() then
		vim.api.nvim_win_call(win, function()
			vim.cmd("normal! G")
		end)
	end
end

-- batch output: many small chunks become one setqflist call
local function push(lines)
	vim.list_extend(queue, lines)
	if not scheduled then
		scheduled = true
		vim.defer_fn(flush_queue, config.flush_ms)
	end
end

-- the first element continues the unfinished line of the previous chunk,
-- the last one may be an unfinished line of this chunk
local function consume(data, stream)
	if not data or #data == 0 then
		return
	end
	data[1] = pending[stream] .. data[1]
	pending[stream] = table.remove(data)
	if #data > 0 then
		push(clean(data))
	end
end

local function finish(id, code)
	if job ~= id then
		return -- a stale job finished after a newer one started
	end
	job = nil
	local finished_qf = qf_id

	for _, s in ipairs({ "stdout", "stderr" }) do
		if pending[s] ~= "" then
			push(clean({ pending[s] }))
			pending[s] = ""
		end
	end
	push({ "", code == 0 and "Process finished successfully." or ("Process exited with code " .. code) })
	flush_queue()

	if finished_qf and vim.fn.getqflist({ id = finished_qf }).id ~= 0 then
		local title = vim.fn.getqflist({ id = finished_qf, title = 0 }).title
		vim.fn.setqflist({}, "a", { id = finished_qf, title = title .. " [exit " .. code .. "]" })
		if code ~= 0 and config.jump_first then
			pcall(vim.cmd, "cfirst")
		end
	end

	vim.notify(
		code == 0 and "Compile successful" or "Compile failed",
		code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
	)

	if code == 0 and config.close_on_success then
		vim.defer_fn(function()
			-- close only if nothing new started and the window still shows this run
			if not job and vim.fn.getqflist({ id = 0 }).id == finished_qf then
				vim.cmd.cclose()
			end
		end, 1000)
	end
end

local function run(cmd)
	if job then
		return vim.notify("Compilation is already running", vim.log.levels.WARN)
	end

	local cwd = vim.fn.getcwd()
	last_cmd, last_cmds[cwd] = cmd, cmd
	current_cmd = cmd
	queue, pending = {}, { stdout = "", stderr = "" }

	-- new list; remember its id to append to exactly this list later
	vim.fn.setqflist({}, " ", { title = cmd, lines = { "$ " .. cmd, "" }, efm = efm() })
	qf_id = vim.fn.getqflist({ id = 0 }).id

	if qf_win() == 0 then
		local cur = vim.api.nvim_get_current_win()
		vim.cmd("botright copen " .. config.height)
		if not config.focus then
			vim.api.nvim_set_current_win(cur)
		end
	end

	local id
	id = vim.fn.jobstart(cmd, {
		cwd = cwd,
		env = { NO_COLOR = "1", TERM = "dumb" }, -- less color noise; merged with the current env
		on_stdout = function(_, data)
			consume(data, "stdout")
		end,
		on_stderr = function(_, data)
			consume(data, "stderr")
		end,
		on_exit = function(_, code)
			finish(id, code)
		end,
	})

	if id <= 0 then
		push({ "Failed to start process." })
		flush_queue()
	else
		job = id
	end
end

-- run `command`, or ask for it (prefilled with the last one for this directory)
function M.compile(command)
	if command and command ~= "" then
		return run(command)
	end
	vim.ui.input({
		prompt = "Compile: ",
		default = last_cmds[vim.fn.getcwd()] or last_cmd or "",
		completion = "shellcmd",
	}, function(value)
		if value and value ~= "" then
			run(value)
		end
	end)
end

function M.repeat_last()
	local cmd = last_cmds[vim.fn.getcwd()] or last_cmd
	if not cmd then
		return vim.notify("No previous compile command", vim.log.levels.WARN)
	end
	run(cmd)
end

function M.stop()
	if job then
		vim.fn.jobstop(job)
	end
end

function M.toggle()
	if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
		vim.cmd.cclose()
	else
		vim.cmd("botright copen " .. config.height)
	end
end

function M.setup(opts)
	config = vim.tbl_extend("force", config, opts or {})

	local cmd = vim.api.nvim_create_user_command
	cmd("Compile", function(o)
		if o.bang then
			M.repeat_last()
		else
			M.compile(o.args)
		end
	end, { nargs = "*", bang = true, complete = "shellcmd", desc = "Compile (! = repeat last)" })
	cmd("CompileStop", M.stop, { desc = "Stop compilation" })
	cmd("CompileQf", M.toggle, { desc = "Toggle quickfix" })
end

return M
