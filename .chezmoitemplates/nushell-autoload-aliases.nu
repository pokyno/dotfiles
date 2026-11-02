alias nvimr = nvim -R
alias fzfe = fzf --exit-0
alias rss = eilmeldung

# lf: pick a subdirectory of the current dir with fzf and cd into it
def --env lf [] {
    let dirs = (ls -a | where type == dir | get name | sort)
    let pick = try {
        $dirs | str join "\n" | fzf --exit-0 --height 40% --reverse --prompt 'cd> ' | str trim
    } catch { "" }
    if $pick != "" { cd $pick }
}
