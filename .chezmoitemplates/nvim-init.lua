-- NOTE: `mapleader` is set in lua/config/lazy.lua, before lazy.nvim loads.
-- It has to happen there: any mapping created while a plugin is being set up
-- bakes in whatever leader is current at that moment.

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
-- `vim.lsp.enable()` is Nvim 0.11+. The installed nvim-lspconfig also refuses to
-- load on anything older than 0.10, so on an older Nvim we skip LSP entirely
-- rather than take the whole config down with us.
if vim.fn.has('nvim-0.11') == 1 then
    vim.lsp.enable("clangd")
else
    vim.schedule(function()
        vim.notify(
            "LSP disabled: clangd setup needs Nvim 0.11+ (running " .. vim.fn.matchstr(vim.fn.execute("version"), 'NVIM v\\zs[^\\n]*') .. ")",
            vim.log.levels.WARN
        )
    end)
end

--****************************************************************************************************************
--Tree sitter setup
--****************************************************************************************************************
-- On nvim-treesitter v0.10.0 the configuration entry point is
-- `nvim-treesitter.configs`; `require("nvim-treesitter").setup()` takes no
-- options and silently ignores anything passed to it.
require('nvim-treesitter.configs').setup {
  -- A list of parser names, or "all" (the listed parsers MUST always be installed)
  ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline", "rust", "nu", "cpp", "json", "python"},

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering a buffer
  auto_install = true,

  ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
  -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

  highlight = {
    enable = true
  }
}

--****************************************************************************************************************
--setup clangd extensions
--****************************************************************************************************************
-- `require("clangd_extensions").setup()` runs from the plugin spec in
-- lua/plugins/clangd_extentions.lua; only the keymap belongs here.
vim.keymap.set('n', '<leader>cf', '<Cmd>ClangdSwitchSourceHeader<CR>', { desc = 'Switch between source/header' })

--****************************************************************************************************************
--setup diffview
--****************************************************************************************************************
-- diffview.nvim loads on demand from its `keys` spec, so it is deliberately not
-- required here.
vim.keymap.set('n', '<leader>dg', '<Cmd>diffg<CR>]c', { silent = true })

--****************************************************************************************************************
--setup nvim-dap
--****************************************************************************************************************
local dap = require("dap")

-- Example configuration for Python
dap.adapters.python = {
    type = 'executable',
    command = {{ if eq .chezmoi.os "windows" }}'python'{{ else }}'python3'{{ end }},
    args = { '-m', 'debugpy.adapter' },
}
dap.configurations.python = {
    {
        type = 'python',
        request = 'launch',
        name = 'Launch file',
        program = '${file}',
        pythonPath = function()
        return {{ if eq .chezmoi.os "windows" }}'python'{{ else }}'/usr/bin/python3'{{ end }}
        end,
    },
}

dap.adapters.gdb = {
  type = "executable",
  command = "gdb",
  args = { "--interpreter=dap", "--eval-command", "set print pretty on" }
}

-- Keybindings for DAP
vim.keymap.set('n', '<F5>', function() require("dap").continue() end, { desc = 'DAP continue' })
vim.keymap.set('n', '<F10>', function() require("dap").step_over() end, { desc = 'DAP step over' })
vim.keymap.set('n', '<F11>', function() require("dap").step_into() end, { desc = 'DAP step into' })
vim.keymap.set('n', '<F12>', function() require("dap").step_out() end, { desc = 'DAP step out' })
vim.keymap.set('n', '<leader>b', function() require("dap").toggle_breakpoint() end, { desc = 'DAP toggle breakpoint' })
vim.keymap.set('n', '<leader>B', function()
    require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = 'DAP conditional breakpoint' })

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
