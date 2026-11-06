local M = {}

local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = "pack" })
end

-- Installs plugins with vim.pack and configures them in list order.
--
-- Entry fields:
--   [1]      "owner/repo" or a full URL
--   name     directory name of the plugin (optional)
--   version  branch, tag, commit or vim.version.range(...) for vim.pack
--   module   name for require() when it differs from the repo name;
--            false means the plugin has no Lua module
--   opts     table passed to module.setup(); nil calls setup() without arguments
--   setup    false disables the automatic setup() call
--   config   function(mod) called after setup (mappings, extra settings)
function M.pack_list(list)
	-- one vim.pack.add call, so the install confirmation is asked only once
	local specs = {}
	for _, p in ipairs(list) do
		local src = p[1]
		if not src:find("^%a+://") then -- "owner/repo" -> GitHub URL
			src = "https://github.com/" .. src
		end
		specs[#specs + 1] = { src = src, name = p.name, version = p.version }
	end
	vim.pack.add(specs)

	-- configure each plugin; an error in one does not stop the others
	for _, p in ipairs(list) do
		local label = p.name or p[1]
		local mod

		if p.module ~= false then
			-- default module name: repo name without the ".nvim" suffix
			local mod_name = p.module or (label:match("[^/]+$"):gsub("%.nvim$", ""))
			local ok, res = pcall(require, mod_name)
			if not ok then
				notify(label .. ": require '" .. mod_name .. "' failed", vim.log.levels.WARN)
				goto continue
			end
			mod = res
			if mod.setup and p.setup ~= false then
				local ok_setup, err = pcall(mod.setup, p.opts)
				if not ok_setup then
					notify(label .. " setup: " .. tostring(err), vim.log.levels.ERROR)
				end
			end
		end

		if p.config then
			local ok_cfg, err = pcall(p.config, mod)
			if not ok_cfg then
				notify(label .. " config: " .. tostring(err), vim.log.levels.ERROR)
			end
		end

		::continue::
	end
end

return M
