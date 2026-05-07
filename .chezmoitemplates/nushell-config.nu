# config.nu
#
# version = "0.109.1"
#
# Overrides default Nushell settings, sets up theme, and establishes
# foundational environment (PATH, EDITOR). Custom commands and aliases
# live in `autoload/*.nu` (sourced automatically after this file).
#
# In-shell documentation:
#     config nu --doc | nu-highlight | less -R

# --- Behavior overrides (deltas from built-in defaults) ---
$env.config.show_banner = false
$env.config.table.mode = "rounded"
$env.config.table.index_mode = "always"
$env.config.history.max_size = 100_000
$env.config.filesize.unit = "binary"
$env.config.cursor_shape.emacs = "line"
$env.config.completions.external.max_results = 100
$env.config.highlight_resolved_externals = false

# --- Theme ---
let dark_theme = {
    separator: white
    leading_trailing_space_bg: { attr: n }
    header: green_bold
    empty: blue
    bool: light_cyan
    int: white
    filesize: cyan
    duration: white
    date: purple
    range: white
    float: white
    string: white
    nothing: white
    binary: white
    cell-path: white
    row_index: green_bold
    record: white
    list: white
    block: white
    hints: dark_gray
    search_result: { bg: red fg: white }
    shape_and: purple_bold
    shape_binary: purple_bold
    shape_block: blue_bold
    shape_bool: light_cyan
    shape_closure: green_bold
    shape_custom: green
    shape_datetime: cyan_bold
    shape_directory: cyan
    shape_external: cyan
    shape_externalarg: green_bold
    shape_external_resolved: light_yellow_bold
    shape_filepath: cyan
    shape_flag: blue_bold
    shape_float: purple_bold
    shape_garbage: { fg: white bg: red attr: b }
    shape_glob_interpolation: cyan_bold
    shape_globpattern: cyan_bold
    shape_int: purple_bold
    shape_internalcall: cyan_bold
    shape_keyword: cyan_bold
    shape_list: cyan_bold
    shape_literal: blue
    shape_match_pattern: green
    shape_matching_brackets: { attr: u }
    shape_nothing: light_cyan
    shape_operator: yellow
    shape_or: purple_bold
    shape_pipe: purple_bold
    shape_range: yellow_bold
    shape_record: cyan_bold
    shape_redirection: purple_bold
    shape_signature: green_bold
    shape_string: green
    shape_string_interpolation: cyan_bold
    shape_table: blue_bold
    shape_variable: purple
    shape_vardecl: purple
    shape_raw_string: light_purple
}
$env.config.color_config = $dark_theme

# --- Environment ---
$env.EDITOR = 'nvim'
{{- if eq .chezmoi.os "linux" }}
$env.PATH ++= ['/opt/nvim-linux-x86_64/bin', '~/.local/bin']
{{- end }}
