# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io). One source
tree deploys to both Linux (`~/.config/...`) and Windows (`%APPDATA%\...`,
`%LOCALAPPDATA%\nvim\...`); a pair of `run_onchange_` install scripts
auto-installs any missing tools and the FiraMono Nerd Font on first apply.

## Tools managed

| Tool      | Linux config              | Windows config                   |
|-----------|---------------------------|----------------------------------|
| bash      | `~/.bashrc`, `~/.profile`, `~/.config/bash/prompt.sh` | _(skipped)_ |
| nushell   | `~/.config/nushell/`      | `%APPDATA%\nushell\`             |
| zoxide    | shell init only (no config) | shell init only                |
| fzf       | shell init only           | shell init only                  |
| zellij    | `~/.config/zellij/`       | `%APPDATA%\zellij\`              |
| yazi      | `~/.config/yazi/`         | `%APPDATA%\yazi\config\`         |
| neovim    | `~/.config/nvim/`         | `%LOCALAPPDATA%\nvim\`           |
| alacritty | `~/.config/alacritty/`    | `%APPDATA%\alacritty\`           |

The font is **FiraMono Nerd Font**, installed automatically.

## Bootstrap

### Linux

```sh
sudo apt install chezmoi git
chezmoi init --apply https://github.com/pokyno/dotfiles.git
```

The install script (`run_onchange_before_install-packages.sh`) uses
`apt` for system packages and `cargo install --locked --version X.Y.Z`
(into `~/.cargo/bin`) for nushell, zellij, yazi+ya, ouch, zoxide.
Versions are pinned at the top of the script — bump them explicitly to
upgrade. If `rustup` is missing, the script bootstraps a minimal stable
toolchain via `https://sh.rustup.rs`. Skips alacritty on WSL (the host
terminal handles the GUI).

### Windows

PowerShell ships with `Restricted` execution policy on client editions,
which blocks the chezmoi-deployed `.ps1` install hook before it parses.
The policy check happens at script load time, so the script can't
self-elevate — allow local scripts once per user before bootstrapping:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
winget install twpayne.chezmoi Git.Git
chezmoi init --apply https://github.com/pokyno/dotfiles.git
```

`RemoteSigned` permits unsigned local scripts (the chezmoi-rendered hook
qualifies) while still requiring signatures on internet-downloaded ones.
No admin rights needed for `CurrentUser` scope.

The install script (`run_onchange_before_install-packages.ps1`) uses
`winget` for git/fzf/yazi/neovim/alacritty/rustup, then
`cargo install --locked --version X.Y.Z` for nushell, zellij, ouch,
zoxide. Bash is not deployed on Windows.

## Layout

```
.
├── .chezmoiignore                  # OS-gates per-side files at apply time
├── .chezmoitemplates/              # canonical content (single source of truth)
├── dot_bashrc, dot_profile         # Linux-only bash entry points
├── dot_config/                     # Linux targets (~/.config/...)
├── AppData/Roaming/                # Windows targets (%APPDATA%\...)
├── AppData/Local/nvim/             # Windows neovim (%LOCALAPPDATA%\nvim\)
└── run_onchange_before_install-packages.{sh,ps1}.tmpl
```

Per-OS target files are thin `.tmpl` wrappers that include the canonical
content from `.chezmoitemplates/` (`{{- template "name" . -}}`). Edits go
to the template once; both Linux and Windows wrappers re-render on apply.

## OS-branched content

A small number of canonical files have inline OS branches:

- `nushell-config.nu` — Linux adds `/opt/nvim-linux-x86_64/bin` and
  `~/.local/bin` to `PATH`; Windows relies on `winget`-set PATH.
- `nvim-init.lua` — DAP `pythonPath` is `/usr/bin/python` on Linux,
  `python` (PATH lookup) on Windows.

The Linux installer omits the alacritty apt entry when
`.chezmoi.kernel.osrelease` contains `microsoft` (i.e. WSL), since
alacritty is a GUI emulator and the terminal is provided by the Windows
host.

## Working with this repo

```sh
chezmoi diff                # preview pending changes
chezmoi apply               # write configs + run installer if changed
chezmoi re-add <path>       # sync edits made to live files back to source
chezmoi cd                  # drop into the source tree
chezmoi managed             # list tracked target paths
```

The Linux installer is `run_onchange_`, so it re-runs only when its own
content changes — adding a tool to the script triggers exactly one
re-execution per machine.

A nushell completion module for chezmoi itself is shipped under
`nushell/autoload/chezmoi-completions.nu`; it registers extern
declarations for the common subcommands and wires
`apply`/`diff`/`cat`/`forget`/`edit`/`re-add`/`status`/`verify` to a
dynamic completer that reads `chezmoi managed`.
