# `source` is parse-time, so ~/.zoxide.nu must exist and define __zoxide_z
# before this file is parsed. env.nu guarantees that (and puts ~/.cargo/bin on
# PATH so `zoxide` itself resolves at runtime).
source ~/.zoxide.nu

# Tab completion for `cd`: the directories under whatever path has been typed
# so far (relative, absolute or ~), so Tab still walks the current directory.
# The argument stays a plain string: a `directory`-typed parameter would be
# expanded to an absolute path and break zoxide keyword queries like `cd proj`.
def _cd_complete [context: string] {
    let token = ($context | split row ' ' | last)
    # Split "foo/ba" into the directory to list ("foo/") and the typed prefix.
    let base = if ($token | str contains '/') {
        $token | str substring 0..($token | str index-of '/' --end)
    } else { '' }
    let dir = if $base == '' { '.' } else { $base | path expand }
    let dirs = try {
        ls -a $dir | where type == dir | get name | each {|p| $base + ($p | path basename) + '/' }
    } catch { [] }
    {
        options: { completion_algorithm: fuzzy, case_sensitive: false, sort: true }
        completions: ($dirs
            | where {|d| ($d | path basename) not-in ['.', '..'] }
            | each {|d| if ($d | str contains ' ') { $'`($d)`' } else { $d } })
    }
}

# cd = zoxide: `cd proj` jumps to a frecent match, `cd some/dir` behaves as usual.
# A wrapper rather than `def cd`, because __zoxide_z itself calls `cd` and would
# then recurse into it; the alias keeps the wrapper's completer.
def --env --wrapped _cd_zoxide [...rest: string@_cd_complete] {
    __zoxide_z ...$rest
}
alias cd = _cd_zoxide
