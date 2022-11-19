local alpha = require("alpha")
local dashboard = require("alpha.themes.dashboard")

dashboard.section.header.val = {
	[[                                                   ]],
	[[                                                   ]],
	[[                                                   ]],
	[[                                                   ]],
	[[                                                   ]],
	[[                                                   ]],
	[[                                                   ]],
	[[ ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗]],
	[[ ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║]],
	[[ ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║]],
	[[ ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║]],
	[[ ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║]],
	[[ ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
	[[                                                   ]],
	[[                                                   ]],
	[[                                                   ]],
	[[                                                   ]],
	[[                                                   ]],
	[[                                                   ]],
}

dashboard.section.buttons.val = {
	dashboard.button("r", "  > Recent", ":History<CR>"),
	dashboard.button("e", "  > New file", ":ene <BAR> startinsert <CR>"),
	dashboard.button("f", "  > Find file", ":Files<CR>"),
	dashboard.button("w", "  > Find word", ":Rg<CR>"),
	dashboard.button("q", "  > Quit NVIM", ":qa<CR>"),
}

dashboard.section.footer = {
	[[ Consider everything deeply but still remain fearless. ]],
}

alpha.setup(dashboard.opts)
