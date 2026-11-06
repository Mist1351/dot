local QF_EFM = "%f:%l - %m,%m"

local function run_components()
	return {
		{ "on_output_quickfix", errorformat = QF_EFM, open = false },
		{ "open_output", on_start = "always", direction = "dock", focus = false },
		"on_complete_notify",
		"default",
	}
end

---@type overseer.TemplateFileProvider
return {
	name = "Godot",

	generator = function(opts)
		if vim.fn.executable("godot") == 0 then
			return 'Command "godot" not found'
		end

		local project = vim.fs.find("project.godot", {
			upward = true,
			type = "file",
			path = opts.dir,
		})[1]
		if not project then
			return "No project.godot file found"
		end

		local root = vim.fs.dirname(project)

		return {
			{
				name = "Godot: Run",
				desc = "Запуск игры",
				builder = function()
					return {
						cmd = { "godot" },
						args = { "--path", root },
						cwd = root,
						components = run_components(),
					}
				end,
			},
			{
				name = "Godot: Editor",
				desc = "Открыть редактор (держит порт LSP)",
				builder = function()
					return {
						cmd = { "godot" },
						args = { "--editor", "--path", root },
						cwd = root,
						components = { "default" },
					}
				end,
			},
			{
				name = "Godot: Headless",
				builder = function()
					return {
						cmd = { "godot" },
						args = { "--headless", "--path", root },
						cwd = root,
						components = run_components(),
					}
				end,
			},
			{
				name = "Godot: Check script",
				desc = "Проверка текущего .gd файла",
				condition = { filetype = { "gdscript" } },
				builder = function()
					local rel = vim.fs.relpath(root, vim.api.nvim_buf_get_name(0))
					if not rel then
						vim.notify("Файл вне проекта Godot", vim.log.levels.WARN)
						return { cmd = { "true" }, components = { "default" } }
					end
					return {
						cmd = { "godot" },
						args = { "--headless", "--path", root, "--check-only", "--script", "res://" .. rel },
						cwd = root,
						components = {
							{ "on_output_quickfix", errorformat = QF_EFM, open = true },
							"on_complete_notify",
							"default",
						},
					}
				end,
			},
			{
				name = "Godot: Import / update UIDs",
				desc = "Headless import: generates missing .uid files and refreshes the resource cache",
				builder = function()
					return {
						cmd = { "godot" },
						args = { "--headless", "--path", root, "--import" },
						cwd = root,
						components = {
							{ "on_output_quickfix", errorformat = QF_EFM, open = false },
							"on_complete_notify",
							"default",
						},
					}
				end,
			},
		}
	end,
}
