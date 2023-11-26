print("hello")
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
vim.api.nvim_set_keymap(
	"v",
	"<leader>c",
	':lua require("totm").copy_selection_to_new_buffer()<cr>',
	{ noremap = true, silent = true }
)

return {
	copy_selection_to_new_buffer = copy_selection_to_new_buffer,
}
