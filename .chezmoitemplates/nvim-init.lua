vim.g.mapleader = "<Space>"

vim.o.tabstop = 4 -- A TAB character looks like 4 spaces
vim.o.expandtab = true -- Pressing the TAB key will insert spaces instead of a TAB character
vim.o.softtabstop = 4 -- Number of spaces inserted instead of a TAB character
vim.o.shiftwidth = 4 -- Number of spaces inserted when indenting

require("config.lazy")

--****************************************************************************************************************
-- theme setup
--****************************************************************************************************************
vim.o.background = "dark" -- or "light" for light mode
vim.cmd([[colorscheme gruvbox]])

--****************************************************************************************************************
-- Set line numbers
--****************************************************************************************************************
vim.o.number = true

--****************************************************************************************************************
-- Telescope keymaps
--****************************************************************************************************************
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

--****************************************************************************************************************
--Setup jq keymaps
--****************************************************************************************************************
vim.keymap.set('n', '<leader>jq', ':%!jq .', { desc = 'Format JSON with jq' })

--****************************************************************************************************************
--Setup lsp
--****************************************************************************************************************
vim.lsp.enable("clangd")

--****************************************************************************************************************
--Tree sitter setup
--****************************************************************************************************************
require'nvim-treesitter'.setup {
  -- A list of parser names, or "all" (the listed parsers MUST always be installed)
  ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline", "rust", "nu", "cpp", "json", "python"},

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
  -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

  highlight = {
    enable = true
  }
}

--****************************************************************************************************************
--setup clangd extensions
--****************************************************************************************************************
require('clangd_extensions').setup {
    keymaps = {
        vim.keymap.set('n', '<leader>cf', '<Cmd>ClangdSwitchSourceHeader<CR>', {desc = 'Switch between source/header'}),
    },
}

--****************************************************************************************************************
--setup diffview
--****************************************************************************************************************
require("diffview")
vim.keymap.set('n', '<leader>dg', '<Cmd>diffg<CR>]c', {silent = true })


--****************************************************************************************************************
-- setup markdown
--****************************************************************************************************************
require('render-markdown').setup({
	pipe_table = { preset = 'heavy'},

	heading = {
        	width = 'block',
        	left_pad = 2,
        	right_pad = 4,
    	},
	indent = { enabled = true },
})

--****************************************************************************************************************
--setup nvim-dap
--****************************************************************************************************************
local dap = require("dap")

-- Example configuration for Python
dap.adapters.python = {
    type = 'executable',
    command = 'python',
    args = { '-m', 'debugpy.adapter' },
}
dap.configurations.python = {
    {
        type = 'python',
        request = 'launch',
        name = 'Launch file',
        program = '${file}',
        pythonPath = function()
        return {{ if eq .chezmoi.os "windows" }}'python'{{ else }}'/usr/bin/python'{{ end }}
        end,
    },
}

dap.adapters.gdb = {
  type = "executable",
  command = "gdb",
  args = { "--interpreter=dap", "--eval-command", "set print pretty on" }
}

-- Keybindings for DAP
vim.api.nvim_set_keymap('n', '<F5>', '<Cmd>lua require"dap".continue()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F10>', '<Cmd>lua require"dap".step_over()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F11>', '<Cmd>lua require"dap".step_into()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F12>', '<Cmd>lua require"dap".step_out()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>b', '<Cmd>lua require"dap".toggle_breakpoint()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>B', '<Cmd>lua require"dap".set_breakpoint(vim.fn.input("Breakpoint condition: "))<CR>', { noremap = true, silent = true })

--gdb configurations for C/C++
dap.configurations.c = {
  {
    name = "Launch",
    type = "gdb",
    request = "launch",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    args = {}, -- provide arguments if needed
    cwd = "${workspaceFolder}",
    stopAtBeginningOfMainSubprogram = false,
  },
  {
    name = "Select and attach to process",
    type = "gdb",
    request = "attach",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    pid = function()
      local name = vim.fn.input('Executable name (filter): ')
      return require("dap.utils").pick_process({ filter = name })
    end,
    cwd = '${workspaceFolder}'
  },
  {
    name = 'Attach to gdbserver :1234',
    type = 'gdb',
    request = 'attach',
    target = 'localhost:1234',
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}'
  }
}

dap.configurations.cpp = dap.configurations.c
dap.configurations.rust = dap.configurations.c

require("toggleterm").setup{
    size = 20,
    open_mapping = [[<c-\>]],
    shade_filetypes = {},
    shade_terminals = true,
    shading_factor = 2,
    start_in_insert = true,
    persist_size = true,
    direction = 'float',
    close_on_exit = true,
    shell = "nu",
}
