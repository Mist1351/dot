local M = {}

function M.setup()
	vim.cmd("hi clear")
	if vim.fn.exists("syntax_on") then
		vim.cmd("syntax reset")
	end
	vim.g.colors_name = "monochrome"

	local is_dark = vim.o.background == "dark"

	local c
	if is_dark then
		c = {
			bg = "#080808",
			fg = "#b0b0b0",
			fg_bright = "#dadada",
			comment = "#707070",
			ui_grey = "#1c1c1c",
			ui_black = "#303030",
			line_nr = "#585858",
			cursor_fg = "#eeeeee",
			cursor_bg = "#303030",
			visual = "#ffaf00",
			visual_bg = "#000000",
			search = "#00afff",
			inc = "#ffaf00",
			cur_srch = "#ff5fff",
			match = "#ffaf00", -- "#ff00af"
			match_fg = "#000000",
			match_bg = "#d787d7",
			cursor_block = "#eeeeee",
			error = "#ff005f",
			todo = "#00ffaf",
			diff_add = "#00af00",
			diff_chg = "#87afd7",
			diff_del = "#d75f5f",
			diff_txt = "#d787d7",
			spell_bad = "#d7005f",
			spell_cap = "#0087d7",
			spell_loc = "#d787d7",
			spell_rar = "#00afaf",
			lime_fg = "#000000",
			lime_bg = "#afff00",
			pmenu_fg = "#000000",
			pmenu_bg = "#a8a8a8",
			pmenu_sel = "#dadada",
			pmenu_match = "#d7005f",
			status_fg = "#eeeeee",
			status_bg = "#222222",
			indent = "#1c1c1c",
			indent_active = "#5c5c5c",
			tab_bg = "#1c1c1c", -- "#060606"
		}
	else
		c = {
			bg = "#e7e7e7",
			fg = "#000000",
			fg_bright = "#000000",
			comment = "#626262",
			ui_grey = "#e4e4e4",
			ui_black = "#eeeeee",
			line_nr = "#a8a8a8",
			cursor_fg = "#b0b0b0",
			cursor_bg = "#eeeeee",
			visual = "#8700d7", -- "#ffaf00"
			visual_bg = "#ffffff", -- "#000000"
			search = "#00afff",
			inc = "#8700d7", -- "#ffaf00"
			cur_srch = "#ff5fff",
			match = "#8700d7", -- "#ff00af", "#ffaf00"
			match_fg = "#ffffff",
			match_bg = "#8700d7",
			cursor_block = "#000000",
			error = "#ff005f",
			todo = "#00ffaf",
			diff_add = "#87d787", -- "#b5e8b0"
			diff_chg = "#afafd7", -- "#e8d4b0"
			diff_del = "#d78787", -- "#e8b0b0"
			diff_txt = "#d787d7",
			spell_bad = "#af0000",
			spell_cap = "#005faf",
			spell_loc = "#870087",
			spell_rar = "#008787",
			lime_fg = "#000000",
			lime_bg = "#afff00",
			pmenu_fg = "#000000",
			pmenu_bg = "#a8a8a8",
			pmenu_sel = "#000000",
			pmenu_match = "#d70000",
			status_fg = "#000000",
			status_bg = "#dadada",
			indent = "#c8c8c8",
			indent_active = "#989898",
			tab_bg = "#cbcbcb",
		}
	end

	local function hi(group, opts)
		local cmd = "highlight " .. group
		if opts.fg then
			cmd = cmd .. " guifg=" .. opts.fg
		end
		if opts.bg then
			cmd = cmd .. " guibg=" .. opts.bg
		end
		if opts.sp then
			cmd = cmd .. " guisp=" .. opts.sp
		end
		cmd = cmd .. " gui=" .. (opts.gui or "NONE")
		vim.cmd(cmd)
	end

	local function link(from, to)
		vim.cmd("highlight! link " .. from .. " " .. to)
	end

	-- UI
	hi("Normal", { fg = c.fg, bg = c.bg })
	hi("NormalFloat", { fg = c.fg, bg = c.ui_grey })
	hi("FloatBorder", { fg = c.comment, bg = c.ui_grey })
	hi("FloatTitle", { fg = c.fg, bg = c.ui_grey, gui = "bold" })
	hi("ColorColumn", { bg = c.ui_grey })
	hi("Conceal", { fg = c.fg, bg = c.bg })
	hi("CurSearch", { fg = c.cur_srch, bg = c.bg, gui = "reverse" })
	hi("Cursor", { fg = c.bg, bg = c.cursor_block })
	hi("lCursor", { fg = c.bg, bg = c.cursor_block })
	hi("CursorColumn", { bg = c.cursor_bg })
	hi("CursorLine", { bg = c.cursor_bg })
	hi("CursorLineNr", { fg = c.fg, bg = c.cursor_bg })
	hi("Directory", { fg = c.fg })
	hi("EndOfBuffer", { fg = c.comment })
	hi("ErrorMsg", { fg = c.fg, bg = c.bg, gui = "reverse" })
	hi("FoldColumn", { fg = c.comment })
	hi("Folded", { fg = c.comment, bg = c.bg })
	hi("IncSearch", { fg = c.inc, bg = c.bg, gui = "reverse" })
	hi("LineNr", { fg = c.line_nr })
	hi("MatchParen", { fg = c.match_fg, bg = c.match_bg, gui = "bold,underline" })
	hi("ModeMsg", { fg = c.fg, gui = "bold" })
	hi("MoreMsg", { fg = c.fg })
	hi("NonText", { fg = c.comment })
	hi("Question", { fg = c.fg })
	hi("QuickFixLine", { fg = c.cur_srch, bg = c.bg, gui = "reverse" })
	hi("Search", { fg = c.search, bg = c.bg, gui = "reverse" })
	hi("SignColumn", { fg = c.fg })
	hi("SpecialKey", { fg = c.comment, gui = "bold" })
	hi("Title", { fg = c.fg, gui = "bold" })
	hi("VertSplit", { fg = c.comment, bg = c.bg })
	hi("WinSeparator", { fg = c.comment, bg = c.bg })
	hi("Visual", { fg = c.visual_bg, bg = c.visual })
	hi("VisualNOS", { bg = c.cursor_bg })
	hi("WarningMsg", { fg = c.fg })
	hi("WildMenu", { fg = c.search, bg = c.bg, gui = "bold" })

	-- Pmenu
	hi("Pmenu", { fg = c.pmenu_fg, bg = c.pmenu_bg })
	hi("PmenuMatch", { fg = c.pmenu_match, bg = c.pmenu_bg })
	hi("PmenuExtra", { fg = c.pmenu_fg, bg = c.pmenu_bg })
	hi("PmenuKind", { fg = c.pmenu_fg, bg = c.pmenu_bg, gui = "bold" })
	hi("PmenuSbar", { fg = c.comment, bg = c.line_nr })
	hi("PmenuSel", { fg = c.bg, bg = c.pmenu_sel })
	hi("PmenuMatchSel", { fg = c.pmenu_match, bg = c.pmenu_sel, gui = "bold" })
	hi("PmenuExtraSel", { fg = c.bg, bg = c.pmenu_sel })
	hi("PmenuKindSel", { fg = c.bg, bg = c.pmenu_sel, gui = "bold" })
	hi("PmenuThumb", { fg = c.fg, bg = c.fg })

	-- StatusLine / TabLine
	hi("StatusLine", { fg = c.status_fg, bg = c.status_bg, gui = "bold" })
	hi("StatusLineNC", { fg = c.comment, bg = c.bg, gui = "reverse" })
	hi("TabLine", { fg = c.comment, bg = c.bg, gui = "reverse" })
	hi("TabLineFill", { fg = c.fg })
	hi("TabLineSel", { fg = c.status_fg, bg = c.status_bg, gui = "bold" })

	-- Diff
	hi("DiffAdd", { fg = c.diff_add, bg = c.bg, gui = "reverse" })
	hi("DiffChange", { fg = c.diff_chg, bg = c.bg, gui = "reverse" })
	hi("DiffDelete", { fg = c.diff_del, bg = c.bg, gui = "reverse" })
	hi("DiffText", { fg = c.diff_txt, bg = c.bg, gui = "reverse" })

	-- Spell
	hi("SpellBad", { sp = c.spell_bad, gui = "undercurl" })
	hi("SpellCap", { sp = c.spell_cap, gui = "undercurl" })
	hi("SpellLocal", { sp = c.spell_loc, gui = "undercurl" })
	hi("SpellRare", { sp = c.spell_rar, gui = "undercurl" })

	hi("CursorIM", { fg = c.lime_fg, bg = c.lime_bg })

	-- Common
	hi("Comment", { fg = c.comment, gui = "italic" })
	hi("Constant", { fg = c.fg })
	hi("String", { fg = c.fg })
	hi("Character", { fg = c.fg })
	hi("Number", { fg = c.fg })
	hi("Float", { fg = c.fg })
	hi("Boolean", { fg = c.fg })
	hi("Identifier", { fg = c.fg })
	hi("Function", { fg = c.fg })
	hi("Statement", { fg = c.fg_bright, gui = "bold" })
	hi("Conditional", { fg = c.fg_bright, gui = "bold" })
	hi("Repeat", { fg = c.fg_bright, gui = "bold" })
	hi("Label", { fg = c.fg_bright, gui = "bold" })
	hi("Operator", { fg = c.fg })
	hi("Keyword", { fg = c.fg_bright, gui = "bold" })
	hi("Exception", { fg = c.fg_bright, gui = "bold" })
	hi("PreProc", { fg = c.fg })
	hi("Include", { fg = c.fg_bright, gui = "bold" })
	hi("Define", { fg = c.fg })
	hi("Macro", { fg = c.fg })
	hi("PreCondit", { fg = c.fg })
	hi("Type", { fg = c.fg })
	hi("StorageClass", { fg = c.fg })
	hi("Structure", { fg = c.fg })
	hi("Typedef", { fg = c.fg })
	hi("Special", { fg = c.fg })
	hi("SpecialChar", { fg = c.fg })
	hi("Tag", { fg = c.fg })
	hi("Delimiter", { fg = c.fg })
	hi("SpecialComment", { fg = c.comment, gui = "italic" })
	hi("Debug", { fg = c.fg })
	hi("Underlined", { fg = c.fg, gui = "underline" })
	hi("Ignore", { fg = c.fg })
	hi("Error", { fg = c.error, bg = c.bg, gui = "bold,reverse" })
	hi("Todo", { fg = c.todo, gui = "bold,reverse" })
	hi("Added", { fg = c.diff_add })
	hi("Changed", { fg = c.diff_chg })
	hi("Removed", { fg = c.diff_del })

	-- Treesitter
	link("@comment", "Comment")
	link("@comment.documentation", "Comment")

	hi("@string", { fg = c.fg })
	hi("@string.escape", { fg = c.fg })
	hi("@string.regex", { fg = c.fg })
	hi("@string.special", { fg = c.fg })
	hi("@number", { fg = c.fg })
	hi("@number.float", { fg = c.fg })
	hi("@character", { fg = c.fg })
	hi("@character.special", { fg = c.fg })
	hi("@boolean", { fg = c.fg })
	hi("@constant", { fg = c.fg })
	hi("@constant.builtin", { fg = c.fg })
	hi("@constant.macro", { fg = c.fg })

	hi("@variable", { fg = c.fg })
	hi("@variable.builtin", { fg = c.fg })
	hi("@variable.parameter", { fg = c.fg })
	hi("@variable.member", { fg = c.fg })

	hi("@function", { fg = c.fg })
	hi("@function.builtin", { fg = c.fg })
	hi("@function.call", { fg = c.fg })
	hi("@function.macro", { fg = c.fg })
	hi("@function.method", { fg = c.fg })
	link("@method", "@function")
	link("@method.call", "@function.call")

	hi("@keyword", { fg = c.fg_bright, gui = "bold" })
	hi("@keyword.coroutine", { fg = c.fg_bright, gui = "bold" })
	hi("@keyword.function", { fg = c.fg_bright, gui = "bold" })
	hi("@keyword.operator", { fg = c.fg_bright, gui = "bold" })
	hi("@keyword.import", { fg = c.fg_bright, gui = "bold" })
	hi("@keyword.type", { fg = c.fg_bright, gui = "bold" })
	hi("@keyword.modifier", { fg = c.fg_bright, gui = "bold" })
	hi("@keyword.repeat", { fg = c.fg_bright, gui = "bold" })
	hi("@keyword.return", { fg = c.fg_bright, gui = "bold" })
	hi("@keyword.debug", { fg = c.fg_bright, gui = "bold" })
	hi("@keyword.exception", { fg = c.fg_bright, gui = "bold" })
	hi("@keyword.conditional", { fg = c.fg_bright, gui = "bold" })
	hi("@keyword.conditional.ternary", { fg = c.fg })
	hi("@keyword.directive", { fg = c.fg })
	hi("@keyword.directive.define", { fg = c.fg })

	link("@conditional", "Conditional")
	link("@repeat", "Repeat")
	link("@exception", "Exception")
	link("@include", "Include")

	hi("@operator", { fg = c.fg })
	hi("@punctuation.bracket", { fg = c.fg })
	hi("@punctuation.delimiter", { fg = c.fg })
	hi("@punctuation.special", { fg = c.fg })

	hi("@type", { fg = c.fg })
	hi("@type.builtin", { fg = c.fg })
	hi("@type.definition", { fg = c.fg })
	hi("@type.qualifier", { fg = c.fg })

	hi("@property", { fg = c.fg })
	hi("@field", { fg = c.fg })
	hi("@module", { fg = c.fg })
	hi("@namespace", { fg = c.fg })
	hi("@label", { fg = c.fg })

	hi("@tag", { fg = c.fg })
	hi("@tag.attribute", { fg = c.fg })
	hi("@tag.delimiter", { fg = c.fg })
	hi("@tag.builtin", { fg = c.fg })

	hi("@markup.heading", { fg = c.fg, gui = "bold" })
	hi("@markup.heading.1", { fg = c.fg, gui = "bold" })
	hi("@markup.heading.2", { fg = c.fg, gui = "bold" })
	hi("@markup.heading.3", { fg = c.fg, gui = "bold" })
	hi("@markup.heading.4", { fg = c.fg, gui = "bold" })
	hi("@markup.heading.5", { fg = c.fg, gui = "bold" })
	hi("@markup.heading.6", { fg = c.fg, gui = "bold" })
	hi("@markup.strong", { gui = "bold" })
	hi("@markup.italic", { gui = "italic" })
	hi("@markup.strikethrough", { gui = "strikethrough" })
	hi("@markup.underline", { gui = "underline" })
	hi("@markup.raw", { fg = c.fg })
	hi("@markup.raw.block", { fg = c.fg })
	hi("@markup.link", { fg = c.fg, gui = "underline" })
	hi("@markup.link.url", { fg = c.comment, gui = "underline" })
	hi("@markup.link.label", { fg = c.fg })
	hi("@markup.list", { fg = c.fg })
	hi("@markup.math", { fg = c.fg })
	link("@markup.quote", "Comment")

	link("@diff.plus", "Added")
	link("@diff.minus", "Removed")
	link("@diff.delta", "Changed")

	-- LSP semantic tokens
	link("@lsp.type.class", "@type")
	link("@lsp.type.struct", "@type")
	link("@lsp.type.enum", "@type")
	link("@lsp.type.enumMember", "Constant")
	link("@lsp.type.interface", "@type")
	link("@lsp.type.typeParameter", "@type")
	link("@lsp.type.namespace", "@module")
	link("@lsp.type.parameter", "@variable.parameter")
	link("@lsp.type.property", "@property")
	link("@lsp.type.variable", "@variable")
	link("@lsp.type.function", "@function")
	link("@lsp.type.method", "@function")
	link("@lsp.type.macro", "@function.macro")
	link("@lsp.type.decorator", "@function")
	link("@lsp.type.keyword", "@keyword")
	link("@lsp.type.comment", "Comment")
	link("@lsp.type.string", "String")
	link("@lsp.type.number", "Number")
	link("@lsp.type.type", "@type")
	link("@lsp.mod.deprecated", "DiagnosticDeprecated")

	-- Diagnostics
	hi("DiagnosticError", { fg = c.spell_bad })
	hi("DiagnosticWarn", { fg = c.visual })
	hi("DiagnosticInfo", { fg = c.spell_cap })
	hi("DiagnosticHint", { fg = c.comment })
	hi("DiagnosticOk", { fg = c.diff_add })

	hi("DiagnosticUnderlineError", { sp = c.spell_bad, gui = "undercurl" })
	hi("DiagnosticUnderlineWarn", { sp = c.visual, gui = "undercurl" })
	hi("DiagnosticUnderlineInfo", { sp = c.spell_cap, gui = "undercurl" })
	hi("DiagnosticUnderlineHint", { sp = c.comment, gui = "undercurl" })
	hi("DiagnosticUnderlineOk", { sp = c.diff_add, gui = "undercurl" })

	hi("DiagnosticVirtualTextError", { fg = c.spell_bad, gui = "italic" })
	hi("DiagnosticVirtualTextWarn", { fg = c.visual, gui = "italic" })
	hi("DiagnosticVirtualTextInfo", { fg = c.spell_cap, gui = "italic" })
	hi("DiagnosticVirtualTextHint", { fg = c.comment, gui = "italic" })
	hi("DiagnosticVirtualTextOk", { fg = c.diff_add, gui = "italic" })

	hi("DiagnosticDeprecated", { fg = c.comment, gui = "strikethrough" })
	hi("DiagnosticUnnecessary", { fg = c.comment })

	link("DiagnosticFloatingError", "DiagnosticError")
	link("DiagnosticFloatingWarn", "DiagnosticWarn")
	link("DiagnosticFloatingInfo", "DiagnosticInfo")
	link("DiagnosticFloatingHint", "DiagnosticHint")
	link("DiagnosticFloatingOk", "DiagnosticOk")
	link("DiagnosticSignError", "DiagnosticError")
	link("DiagnosticSignWarn", "DiagnosticWarn")
	link("DiagnosticSignInfo", "DiagnosticInfo")
	link("DiagnosticSignHint", "DiagnosticHint")
	link("DiagnosticSignOk", "DiagnosticOk")

	-- LSP
	hi("LspReferenceText", { bg = c.cursor_bg })
	hi("LspReferenceRead", { bg = c.cursor_bg })
	hi("LspReferenceWrite", { bg = c.cursor_bg, gui = "bold" })
	hi("LspSignatureActiveParameter", { gui = "bold,underline" })
	hi("LspCodeLens", { fg = c.comment, gui = "italic" })
	hi("LspCodeLensSeparator", { fg = c.comment })
	hi("LspInlayHint", { fg = c.comment, gui = "italic" })

	-- lazy.nvim
	link("LazyButton", "PmenuSel")
	link("LazyButtonActive", "Visual")
	hi("LazyH1", { fg = c.status_fg, bg = c.status_bg, gui = "bold" })
	hi("LazyH2", { fg = c.fg, gui = "bold" })
	link("LazyComment", "Comment")
	link("LazyProp", "Comment")
	link("LazyDimmed", "Comment")
	link("LazySpecial", "Special")
	link("LazyReasonPlugin", "Comment")
	link("LazyReasonEvent", "Comment")
	link("LazyReasonKeys", "Comment")
	link("LazyReasonFt", "Comment")
	link("LazyReasonCmd", "Comment")
	link("LazyReasonSource", "Comment")
	link("LazyReasonRuntime", "Comment")
	link("LazyReasonImport", "Comment")
	link("LazyReasonStart", "Comment")

	-- Telescope
	hi("TelescopeNormal", { fg = c.fg, bg = c.ui_grey })
	hi("TelescopeBorder", { fg = c.comment, bg = c.ui_grey })
	hi("TelescopeTitle", { fg = c.fg, gui = "bold" })
	hi("TelescopePromptNormal", { fg = c.fg, bg = c.ui_grey })
	hi("TelescopePromptBorder", { fg = c.comment, bg = c.ui_grey })
	hi("TelescopePromptTitle", { fg = c.fg, gui = "bold" })
	hi("TelescopeResultsNormal", { fg = c.fg, bg = c.ui_grey })
	hi("TelescopeResultsBorder", { fg = c.comment, bg = c.ui_grey })
	hi("TelescopePreviewNormal", { fg = c.fg, bg = c.ui_grey })
	hi("TelescopePreviewBorder", { fg = c.comment, bg = c.ui_grey })
	hi("TelescopePreviewTitle", { fg = c.fg, gui = "bold" })
	hi("TelescopeSelection", { bg = c.cursor_bg })
	link("TelescopeMatching", "Search")
	link("TelescopeSelectionCaret", "TelescopeSelection")

	-- nvim-cmp
	link("CmpItemAbbr", "Normal")
	hi("CmpItemAbbrDeprecated", { fg = c.comment, gui = "strikethrough" })
	hi("CmpItemAbbrMatch", { fg = c.fg, gui = "bold" })
	hi("CmpItemAbbrMatchFuzzy", { fg = c.fg, gui = "bold" })
	link("CmpItemKind", "Comment")
	link("CmpItemMenu", "Comment")

	local cmp_kinds = {
		"CmpItemKindText",
		"CmpItemKindMethod",
		"CmpItemKindFunction",
		"CmpItemKindConstructor",
		"CmpItemKindField",
		"CmpItemKindVariable",
		"CmpItemKindClass",
		"CmpItemKindInterface",
		"CmpItemKindModule",
		"CmpItemKindProperty",
		"CmpItemKindUnit",
		"CmpItemKindValue",
		"CmpItemKindEnum",
		"CmpItemKindKeyword",
		"CmpItemKindSnippet",
		"CmpItemKindColor",
		"CmpItemKindFile",
		"CmpItemKindReference",
		"CmpItemKindFolder",
		"CmpItemKindEnumMember",
		"CmpItemKindConstant",
		"CmpItemKindStruct",
		"CmpItemKindEvent",
		"CmpItemKindOperator",
		"CmpItemKindTypeParameter",
	}
	for _, kind in ipairs(cmp_kinds) do
		hi(kind, { fg = c.comment })
	end

	-- blink.cmp
	link("BlinkCmpMenu", "NormalFloat")
	link("BlinkCmpMenuBorder", "FloatBorder")
	link("BlinkCmpMenuSelection", "PmenuSel")
	hi("BlinkCmpLabel", { fg = c.fg })
	hi("BlinkCmpLabelMatch", { fg = c.fg, gui = "bold" })
	hi("BlinkCmpLabelDeprecated", { fg = c.comment, gui = "strikethrough" })
	hi("BlinkCmpLabelDetail", { fg = c.comment })
	hi("BlinkCmpLabelDescription", { fg = c.comment })
	link("BlinkCmpKind", "Comment")
	link("BlinkCmpDoc", "NormalFloat")
	link("BlinkCmpDocBorder", "FloatBorder")
	link("BlinkCmpSignatureHelp", "NormalFloat")
	link("BlinkCmpSignatureHelpBorder", "FloatBorder")

	-- Neo-tree
	link("NeoTreeNormal", "Normal")
	link("NeoTreeNormalNC", "Normal")
	hi("NeoTreeDimText", { fg = c.comment })
	link("NeoTreeFileName", "Normal")
	link("NeoTreeDirectoryName", "Directory")
	link("NeoTreeDirectoryIcon", "Directory")
	hi("NeoTreeRootName", { fg = c.fg, gui = "bold" })
	hi("NeoTreeGitAdded", { fg = c.diff_add })
	hi("NeoTreeGitModified", { fg = c.diff_chg })
	hi("NeoTreeGitDeleted", { fg = c.diff_del })
	hi("NeoTreeGitUntracked", { fg = c.comment })
	link("NeoTreeIndentMarker", "Comment")
	link("NeoTreeExpander", "Comment")

	-- nvim-tree
	link("NvimTreeNormal", "Normal")
	link("NvimTreeRootFolder", "NeoTreeRootName")
	link("NvimTreeFolderName", "Directory")
	link("NvimTreeFolderIcon", "Directory")
	link("NvimTreeIndentMarker", "Comment")
	hi("NvimTreeGitDirty", { fg = c.diff_chg })
	hi("NvimTreeGitNew", { fg = c.diff_add })
	hi("NvimTreeGitDeleted", { fg = c.diff_del })

	-- Gitsigns
	hi("GitSignsAdd", { fg = c.diff_add })
	hi("GitSignsChange", { fg = c.diff_chg })
	hi("GitSignsDelete", { fg = c.diff_del })
	link("GitSignsAddNr", "GitSignsAdd")
	link("GitSignsChangeNr", "GitSignsChange")
	link("GitSignsDeleteNr", "GitSignsDelete")
	link("GitSignsAddLn", "DiffAdd")
	link("GitSignsChangeLn", "DiffChange")
	link("GitSignsDeleteLn", "DiffDelete")
	hi("GitSignsCurrentLineBlame", { fg = c.comment, gui = "italic" })

	-- Which-key
	hi("WhichKey", { fg = c.fg, gui = "bold" })
	hi("WhichKeyGroup", { fg = c.fg_bright, gui = "bold" })
	hi("WhichKeyDesc", { fg = c.fg })
	hi("WhichKeySeparator", { fg = c.comment })
	hi("WhichKeyValue", { fg = c.comment })
	link("WhichKeyNormal", "NormalFloat")
	link("WhichKeyBorder", "FloatBorder")
	link("WhichKeyTitle", "FloatTitle")

	-- Oil
	hi("OilPermissionNone", { fg = c.comment })
	hi("OilPermissionRead", { fg = c.fg })
	hi("OilPermissionWrite", { fg = c.fg_bright, gui = "bold" })
	hi("OilPermissionExecute", { fg = c.fg_bright, gui = "bold" })
	hi("OilSize", { fg = c.comment })
	hi("OilMtime", { fg = c.comment })

	-- mini.pick
	link("MiniPickNormal", "NormalFloat")
	link("MiniPickBorder", "FloatBorder")
	link("MiniPickBorderBusy", "FloatBorder")
	hi("MiniPickBorderText", { fg = c.fg, bg = c.ui_grey, gui = "bold" })
	hi("MiniPickPrompt", { fg = c.fg_bright, bg = c.ui_grey })
	link("MiniPickMatchCurrent", "PmenuSel")
	hi("MiniPickMatchMarked", { fg = c.visual_bg, bg = c.visual })
	hi("MiniPickMatchRanges", { fg = c.fg_bright, gui = "bold,underline" })
	link("MiniPickPreviewLine", "CursorLine")
	link("MiniPickHeader", "Comment")

	-- Indent-blankline / mini.indentscope
	hi("IblIndent", { fg = c.indent })
	hi("IblScope", { fg = c.indent_active })
	hi("MiniIndentscopeSymbol", { fg = c.comment })

	-- Noice
	link("NoiceCmdline", "Normal")
	link("NoiceCmdlinePopup", "NormalFloat")
	link("NoiceCmdlinePopupBorder", "FloatBorder")
	link("NoiceConfirm", "NormalFloat")
	link("NoiceConfirmBorder", "FloatBorder")
	link("NoiceMini", "Comment")
	link("NoiceFormatProgressDone", "Visual")
	link("NoiceFormatProgressTodo", "StatusLineNC")
	link("NoiceLspProgressTitle", "Normal")
	link("NoiceLspProgressClient", "Comment")
	link("NoiceLspProgressSpinner", "Comment")

	-- Notify
	hi("NotifyERRORBorder", { fg = c.spell_bad })
	hi("NotifyERRORIcon", { fg = c.spell_bad })
	hi("NotifyERRORTitle", { fg = c.spell_bad })
	hi("NotifyWARNBorder", { fg = c.visual })
	hi("NotifyWARNIcon", { fg = c.visual })
	hi("NotifyWARNTitle", { fg = c.visual })
	hi("NotifyINFOBorder", { fg = c.comment })
	hi("NotifyINFOIcon", { fg = c.comment })
	hi("NotifyINFOTitle", { fg = c.comment })
	hi("NotifyDEBUGBorder", { fg = c.comment })
	hi("NotifyDEBUGIcon", { fg = c.comment })
	hi("NotifyDEBUGTitle", { fg = c.comment })
	hi("NotifyTRACEBorder", { fg = c.comment })
	hi("NotifyTRACEIcon", { fg = c.comment })
	hi("NotifyTRACETitle", { fg = c.comment })
	link("NotifyBackground", "NormalFloat")

	-- Snacks.nvim
	link("SnacksDashboardHeader", "Title")
	link("SnacksDashboardFooter", "Comment")
	link("SnacksDashboardDesc", "Normal")
	link("SnacksDashboardIcon", "Normal")
	link("SnacksDashboardKey", "Normal")
	link("SnacksDashboardSpecial", "Comment")
	link("SnacksNormal", "NormalFloat")
	link("SnacksBorder", "FloatBorder")
	link("SnacksNotifierInfo", "NotifyINFOTitle")
	link("SnacksNotifierWarn", "NotifyWARNTitle")
	link("SnacksNotifierError", "NotifyERRORTitle")
	link("SnacksNotifierDebug", "NotifyDEBUGTitle")
	link("SnacksNotifierTrace", "NotifyTRACETitle")

	-- Flash.nvim
	hi("FlashBackdrop", { fg = c.comment })
	hi("FlashLabel", { fg = c.bg, bg = c.fg, gui = "bold" })
	hi("FlashMatch", { fg = c.search, bg = c.bg, gui = "reverse" })
	hi("FlashCurrent", { fg = c.inc, bg = c.bg, gui = "reverse" })

	-- Mini.statusline
	link("MiniStatuslineDevinfo", "StatusLine")
	link("MiniStatuslineFileinfo", "StatusLine")
	link("MiniStatuslineFilename", "StatusLineNC")
	link("MiniStatuslineInactive", "StatusLineNC")
	link("MiniStatuslineModeNormal", "StatusLine")
	link("MiniStatuslineModeInsert", "StatusLine")
	link("MiniStatuslineModeVisual", "StatusLine")
	link("MiniStatuslineModeReplace", "StatusLine")
	link("MiniStatuslineModeCommand", "StatusLine")
	link("MiniStatuslineModeOther", "StatusLine")

	-- Trouble
	link("TroubleNormal", "Normal")
	link("TroubleNormalNC", "Normal")
	link("TroubleText", "Normal")
	link("TroubleCount", "Normal")
	link("TroubleCode", "Comment")
	link("TroubleFile", "Normal")
	link("TroubleFoldIcon", "Comment")
	link("TroubleIndent", "Comment")
	link("TroubleLocation", "Comment")
	link("TroublePreview", "Search")
	link("TroubleSource", "Comment")
	link("TroubleSignError", "DiagnosticSignError")
	link("TroubleSignWarning", "DiagnosticSignWarn")
	link("TroubleSignInformation", "DiagnosticSignInfo")
	link("TroubleSignHint", "DiagnosticSignHint")

	-- bufferline.nvim
	local accent = c.visual -- оранжевый в тёмной, фиолетовый в светлой теме

	hi("BufferLineFill", { bg = c.tab_bg })
	hi("BufferLineBackground", { fg = c.comment, bg = c.tab_bg })

	-- Inactive
	hi("BufferLineBuffer", { fg = c.comment, bg = c.tab_bg })
	hi("BufferLineCloseButton", { fg = c.comment, bg = c.tab_bg })
	hi("BufferLineModified", { fg = c.comment, bg = c.tab_bg })
	hi("BufferLineNumbers", { fg = c.comment, bg = c.tab_bg })
	hi("BufferLineDuplicate", { fg = c.comment, bg = c.tab_bg, gui = "italic" })
	hi("BufferLinePick", { fg = c.error, bg = c.tab_bg, gui = "bold" })

	--
	hi("BufferLineBufferVisible", { fg = c.fg, bg = c.tab_bg })
	hi("BufferLineCloseButtonVisible", { fg = c.fg, bg = c.tab_bg })
	hi("BufferLineModifiedVisible", { fg = c.fg, bg = c.tab_bg })
	hi("BufferLineNumbersVisible", { fg = c.fg, bg = c.tab_bg })
	hi("BufferLineDuplicateVisible", { fg = c.fg, bg = c.tab_bg, gui = "italic" })
	hi("BufferLinePickVisible", { fg = c.error, bg = c.tab_bg, gui = "bold" })

	--
	hi("BufferLineBufferSelected", { fg = c.fg_bright, bg = c.bg, gui = "bold" })
	hi("BufferLineCloseButtonSelected", { fg = accent, bg = c.bg })
	hi("BufferLineModifiedSelected", { fg = accent, bg = c.bg, gui = "bold" })
	hi("BufferLineNumbersSelected", { fg = c.fg_bright, bg = c.bg, gui = "bold" })
	hi("BufferLineDuplicateSelected", { fg = c.fg_bright, bg = c.bg, gui = "bold,italic" })
	hi("BufferLinePickSelected", { fg = c.error, bg = c.bg, gui = "bold" })
	hi("BufferLineIndicatorSelected", { fg = accent, bg = c.bg })
	hi("BufferLineIndicatorVisible", { fg = c.tab_bg, bg = c.tab_bg })

	-- tabpages
	hi("BufferLineTab", { fg = c.comment, bg = c.tab_bg })
	hi("BufferLineTabSelected", { fg = c.fg_bright, bg = c.bg, gui = "bold" })
	hi("BufferLineTabClose", { fg = c.comment, bg = c.tab_bg })

	-- separators
	hi("BufferLineSeparator", { fg = c.tab_bg, bg = c.tab_bg })
	hi("BufferLineSeparatorVisible", { fg = c.tab_bg, bg = c.tab_bg })
	hi("BufferLineSeparatorSelected", { fg = c.tab_bg, bg = c.bg })
	hi("BufferLineOffsetSeparator", { fg = c.comment, bg = c.bg })
	hi("BufferLineTruncMarker", { fg = c.comment, bg = c.tab_bg })

	-- Bufferline diagnostics
	hi("BufferLineWarning", { fg = c.comment, bg = c.tab_bg })
	hi("BufferLineWarningVisible", { fg = c.fg, bg = c.tab_bg })
	hi("BufferLineWarningSelected", { fg = c.comment, bg = c.bg, gui = "bold" })
	hi("BufferLineWarningDiagnostic", { fg = c.comment, bg = c.tab_bg })
	hi("BufferLineWarningDiagnosticVisible", { fg = c.fg, bg = c.tab_bg })
	hi("BufferLineWarningDiagnosticSelected", { fg = c.comment, bg = c.bg, gui = "bold" })

	hi("BufferLineError", { fg = c.spell_bad, bg = c.tab_bg })
	hi("BufferLineErrorVisible", { fg = c.fg, bg = c.tab_bg })
	hi("BufferLineErrorSelected", { fg = c.spell_bad, bg = c.bg, gui = "bold" })
	hi("BufferLineErrorDiagnostic", { fg = c.spell_bad, bg = c.tab_bg })
	hi("BufferLineErrorDiagnosticVisible", { fg = c.fg, bg = c.tab_bg })
	hi("BufferLineErrorDiagnosticSelected", { fg = c.spell_bad, bg = c.bg, gui = "bold" })

	hi("BufferLineInfo", { fg = c.spell_loc, bg = c.tab_bg })
	hi("BufferLineInfoVisible", { fg = c.fg, bg = c.tab_bg })
	hi("BufferLineInfoSelected", { fg = c.spell_loc, bg = c.bg, gui = "bold" })
	hi("BufferLineInfoDiagnostic", { fg = c.spell_loc, bg = c.tab_bg })
	hi("BufferLineInfoDiagnosticVisible", { fg = c.fg, bg = c.tab_bg })
	hi("BufferLineInfoDiagnosticSelected", { fg = c.spell_loc, bg = c.bg, gui = "bold" })

	hi("BufferLineHint", { fg = c.spell_rar, bg = c.tab_bg })
	hi("BufferLineHintVisible", { fg = c.fg, bg = c.tab_bg })
	hi("BufferLineHintSelected", { fg = c.spell_rar, bg = c.bg, gui = "bold" })
	hi("BufferLineHintDiagnostic", { fg = c.spell_rar, bg = c.tab_bg })
	hi("BufferLineHintDiagnosticVisible", { fg = c.fg, bg = c.tab_bg })
	hi("BufferLineHintDiagnosticSelected", { fg = c.spell_rar, bg = c.bg, gui = "bold" })

	-- Mason
	link("MasonNormal", "NormalFloat")
	link("MasonHeader", "Title")

	-- Navic
	hi("NavicText", { fg = c.fg })
	hi("NavicSeparator", { fg = c.comment })
	local navic_kinds = {
		"NavicIconsFile",
		"NavicIconsModule",
		"NavicIconsNamespace",
		"NavicIconsPackage",
		"NavicIconsClass",
		"NavicIconsMethod",
		"NavicIconsProperty",
		"NavicIconsField",
		"NavicIconsConstructor",
		"NavicIconsEnum",
		"NavicIconsInterface",
		"NavicIconsFunction",
		"NavicIconsVariable",
		"NavicIconsConstant",
		"NavicIconsString",
		"NavicIconsNumber",
		"NavicIconsBoolean",
		"NavicIconsArray",
		"NavicIconsObject",
		"NavicIconsKey",
		"NavicIconsNull",
		"NavicIconsEnumMember",
		"NavicIconsStruct",
		"NavicIconsEvent",
		"NavicIconsOperator",
		"NavicIconsTypeParameter",
	}
	for _, kind in ipairs(navic_kinds) do
		hi(kind, { fg = c.comment })
	end

	-- Terminal colors
	if is_dark then
		vim.g.terminal_color_0 = "#000000"
		vim.g.terminal_color_1 = "#d7005f"
		vim.g.terminal_color_2 = "#00af5f"
		vim.g.terminal_color_3 = "#d78700"
		vim.g.terminal_color_4 = "#0087d7"
		vim.g.terminal_color_5 = "#d787d7"
		vim.g.terminal_color_6 = "#00afaf"
		vim.g.terminal_color_7 = "#dadada"
		vim.g.terminal_color_8 = "#707070"
		vim.g.terminal_color_9 = "#ff005f"
		vim.g.terminal_color_10 = "#00d75f"
		vim.g.terminal_color_11 = "#ffaf00"
		vim.g.terminal_color_12 = "#5fafff"
		vim.g.terminal_color_13 = "#ff87ff"
		vim.g.terminal_color_14 = "#00d7d7"
		vim.g.terminal_color_15 = "#ffffff"
	else
		vim.g.terminal_color_0 = "#000000"
		vim.g.terminal_color_1 = "#af0000"
		vim.g.terminal_color_2 = "#005f00"
		vim.g.terminal_color_3 = "#af5f00"
		vim.g.terminal_color_4 = "#005faf"
		vim.g.terminal_color_5 = "#870087"
		vim.g.terminal_color_6 = "#008787"
		vim.g.terminal_color_7 = "#d7d7d7"
		vim.g.terminal_color_8 = "#626262"
		vim.g.terminal_color_9 = "#d70000"
		vim.g.terminal_color_10 = "#008700"
		vim.g.terminal_color_11 = "#d78700"
		vim.g.terminal_color_12 = "#0087d7"
		vim.g.terminal_color_13 = "#af00af"
		vim.g.terminal_color_14 = "#00afaf"
		vim.g.terminal_color_15 = "#ffffff"
	end

	vim.opt.guicursor = {
		"n-v-c-sm:block-Cursor/lCursor",
		"i-ci-ve:ver25-Cursor/lCursor",
		"r-cr-o:hor20-Cursor/lCursor",
		"t:block-blinkon500-blinkoff500-TermCursor",
	}
end

M.setup()

return M
