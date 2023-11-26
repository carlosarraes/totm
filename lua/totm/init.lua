local function copy_selection_to_new_buffer()
	local bufnr = vim.api.nvim_get_current_buf()
	local start_pos = vim.api.nvim_buf_get_mark(bufnr, "<")
	local end_pos = vim.api.nvim_buf_get_mark(bufnr, ">")

	end_pos[1] = end_pos[1] + 1

	local lines = vim.api.nvim_buf_get_lines(bufnr, start_pos[1] - 1, end_pos[1], false)
	local current_filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
	table.insert(lines, 1, "```" .. current_filetype)
	table.insert(lines, "```")

	local new_buffer = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_buf_set_lines(new_buffer, 0, -1, false, lines)

	local timestamp = os.date("%y-%m-%d-%h-%m-%s")
	local temp_file_name = "/tmp/totm-" .. timestamp .. ".txt"

	vim.api.nvim_buf_set_name(new_buffer, temp_file_name)
	vim.api.nvim_buf_set_option(new_buffer, "filetype", "markdown")

	vim.cmd("vsplit")
	vim.api.nvim_set_current_buf(new_buffer)
end

local function send_buffer_to_api()
	print("sending buffer to api")
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local payload = table.concat(lines, "\\n")

	payload = payload:gsub("\t", "\\t"):gsub("\n", "\\n"):gsub('"', '\\"')

	local model = "codellama:7b"
	local prompt = string.format('{"model": "%s", "prompt": "%s", "stream": false}', model, payload)

	local function on_event(_, data, event)
		if event == "stdout" and not vim.tbl_isempty(data) then
			local response = table.concat(data, "")
			local json_data = vim.fn.json_decode(response)
			if json_data and json_data.response then
				local response_lines = vim.split(json_data.response, "\n")
				vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, response_lines)
			end
		end
	end

	local cmd = {
		"curl",
		"-X",
		"POST",
		"http://localhost:11434/api/generate",
		"-H",
		"Content-Type: application/json",
		"-d",
		prompt,
	}

	vim.fn.jobstart(cmd, {
		on_stderr = on_event,
		on_stdout = on_event,
		stdout_buffered = true,
		stderr_buffered = true,
	})
	print("sent buffer to api")
end

vim.api.nvim_set_keymap(
	"v",
	"<leader>cd",
	':lua require("totm").copy_selection_to_new_buffer()<cr>',
	{ noremap = true, silent = true }
)

vim.api.nvim_set_keymap(
	"n",
	"<leader>ca",
	':lua require("totm").send_buffer_to_api()<cr>',
	{ noremap = true, silent = true }
)

return {
	copy_selection_to_new_buffer = copy_selection_to_new_buffer,
	send_buffer_to_api = send_buffer_to_api,
}
