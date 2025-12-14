local M = {}

local S = {}

local function get_wd()
	local arg = vim.fn.argv(0)
	if arg ~= "" and vim.fn.isdirectory(arg) == 1 then
		return vim.fn.getcwd() .. "/" .. arg
	end
	return vim.fn.getcwd()
end

local function get_fn()
	local path = get_wd() .. "/clean-marks.json"
	local name = path:gsub("[/]", "-")
	if name:sub(1, 1) == "-" then
		name = name:sub(2)
	end
	return name
end

local OPTS = {
	max_length = 4,
	filename = get_fn(),
	datadir = vim.fn.stdpath("data") .. "/clean-marks",
	logging_enabled = false,
	mappings = {
		set_mark = "<leader>m",
		goto_mark = "<leader>'",
		float_window = "<leader>cm",
	},
	window = {
		height = 0.9,
		width = 0.66,
	},
}

local function log(msg)
	if OPTS.logging_enabled then
		vim.notify(string.format("clean-marks.nvim: %s", msg), vim.log.levels.DEBUG)
	end
end

local function load_state()
	log("loading state")
	vim.fn.mkdir(OPTS.datadir, "p")
	local ok, fd = pcall(io.open, OPTS.datadir .. "/" .. OPTS.filename)
	if not ok or fd == nil then
		log("failed to open the data file for reading")
		return
	end
	local content = fd:read("*a")
	fd:close()
	S = vim.fn.json_decode(content)
end

local function write_state()
	log("writing state")
	local ok, fd = pcall(io.open, OPTS.datadir .. "/" .. OPTS.filename, "w")
	if not ok or fd == nil then
		log("failed to open the data file for writing")
		return
	end
	local content = vim.fn.json_encode(S)
	local ok, pretty = pcall(vim.fn.systemlist, { "jq", "." }, content)
	if ok and vim.v.shell_error == 0 then
		fd:write(table.concat(pretty, "\n"))
	else
		log("failed to 'jq' the json, is the binary missing?")
		fd:write(content)
	end
	fd:close()
end

local function get_stR()
	local str = ""
	for _ = 1, OPTS.max_length do
		local c = vim.fn.getcharstr()
		if string.byte("a") <= c:byte() and c:byte() <= string.byte("z") then
			str = str .. c
		elseif string.byte("A") <= c:byte() and c:byte() <= string.byte("Z") then
			str = str .. c
			return true, str
		else
			return false, ""
		end
	end
	return false, ""
end

local function set_mark()
	log("setting a mark")
	local ok, mark = get_stR()
	if ok then
		S[mark] = vim.fn.expand("%:p")
		write_state()
	else
		log("failed to set mark")
	end
end

local function goto_mark()
	local ok, mark = get_stR()
	if not ok then
		log("could not read mark")
		return
	end
	local path = S[mark]
	if path == nil then
		log("mark was not set")
		return
	end
	local restore_cursor = function()
		local ok, _ = pcall(vim.cmd, [[norm! `"]])
		if not ok then
			log("could not restore cursor position. try a larger shada?")
		end
	end
	local bufs = vim.api.nvim_list_bufs()
	for _, buf in ipairs(bufs) do
		if vim.api.nvim_buf_get_name(buf) == path then
			log("restoring buffer")
			vim.api.nvim_set_current_buf(buf)
			restore_cursor()
			return
		end
	end
	if vim.uv.fs_stat(path) ~= nil then
		log("editing the file")
		vim.cmd("edit " .. vim.fn.fnameescape(path))
		restore_cursor()
	else
		log(string.format("file [%s] does not exist", path))
	end
end

local function float_window()
	local buf = vim.fn.bufnr(OPTS.datadir .. "/" .. OPTS.filename, true)
	vim.fn.bufload(buf)
	local height = math.floor(vim.o.lines * OPTS.window.height)
	local width = math.floor(vim.o.columns * OPTS.window.width)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		style = "minimal",
		border = "rounded",
		row = row,
		col = col,
		width = width,
		height = height,
	})
	vim.api.nvim_create_autocmd("BufWritePost", {
		buffer = buf,
		callback = function()
			load_state()
		end,
	})
end

local function init_mappings()
	local maps = OPTS.mappings or {}
	if maps.set_mark then
		vim.keymap.set("n", maps.set_mark, set_mark)
	end
	if maps.goto_mark then
		vim.keymap.set("n", maps.goto_mark, goto_mark)
	end
	if maps.float_window then
		vim.keymap.set("n", maps.float_window, float_window)
	end
	vim.api.nvim_create_user_command("CleanMarks", float_window, {})
end

M.setup = function(opts)
	OPTS = vim.tbl_extend("force", OPTS, opts)
	init_mappings()
	load_state()
end

M.set_mark = set_mark
M.goto_mark = goto_mark
M.float_window = float_window

return M
