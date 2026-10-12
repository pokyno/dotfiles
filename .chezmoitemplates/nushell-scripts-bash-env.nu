# bash-env.nu: import the environment a bash script produces into nushell.
# Dependency-free port of tesujimath/bash-env-json + bash-env-nushell:
# needs only bash (builtins) and nushell. No jq, env, sed, mktemp.
#
#   bash-env ./setup.bash            # record of new/changed exported vars
#   bash-env ./setup.bash | load-env # apply them
#   bash-env load ./setup.bash       # apply, incl. unsets and PATH -> list
#   bash-env -s ./setup.bash         # {env, shellvars}
#   bash-env -f [f1 f2] ./setup.bash # also run functions f1, f2 and capture
#   echo "export A=1" | bash-env     # script on stdin

# Runs in bash as `bash -c $script bash-env [--fn a,b] [path]`.
# Protocol on stdout: NUL-separated fields, 3 per record (kind, name, value):
#   E name value   exported variable        S name value   shell variable
#   - label  ""    end of snapshot `label`: before, after, then one per fn
# The sourced script's stdout is discarded; its stderr passes through and a
# failure exits non-zero, so nushell gets the error text via `complete`.
const script = r#'
__be_snapshot() {
    local __be_line __be_flags __be_name
    while IFS= read -r __be_line; do
        [[ $__be_line =~ ^declare\ -([^\ ]+)\ ([A-Za-z_][A-Za-z0-9_]*)= ]] || continue
        __be_flags=${BASH_REMATCH[1]}; __be_name=${BASH_REMATCH[2]}
        case "$__be_name" in
            __be_*|_|PWD|OLDPWD|SHLVL|BASHPID|BASH_COMMAND|BASH_SUBSHELL|BASH_EXECUTION_STRING|EPOCHREALTIME|EPOCHSECONDS|HISTCMD|LINENO|RANDOM|SRANDOM|SECONDS|COLUMNS|LINES|COMP_WORDBREAKS) continue ;;
        esac
        case "$__be_flags" in *[aAn]*) continue ;; esac   # arrays, namerefs
        case "$__be_flags" in
            *x*) printf 'E\0%s\0%s\0' "$__be_name" "${!__be_name}" ;;
            *)   printf 'S\0%s\0%s\0' "$__be_name" "${!__be_name}" ;;
        esac
    done <<<"$(declare -p)"
    printf -- '-\0%s\0\0' "$1"
}
__be_fns=; __be_path=
while [ $# -gt 0 ]; do
    case "$1" in
        --fn) __be_fns=$2; shift 2 ;;
        *) __be_path=$1; shift ;;
    esac
done
__be_snapshot before
if [ -n "$__be_path" ]; then
    [ -r "$__be_path" ] || { printf "no such file '%s'\n" "$__be_path" >&2; exit 1; }
    source "$__be_path" >/dev/null || exit 1
else
    __be_src=$(</dev/stdin)
    eval "$__be_src" >/dev/null || exit 1
fi
__be_snapshot after
IFS=, read -ra __be_fn_list <<<"$__be_fns"
for __be_fn in "${__be_fn_list[@]}"; do
    "$__be_fn" >/dev/null || exit 1
    __be_snapshot "$__be_fn"
done
'#

# raw protocol output -> { before: {env, shellvars}, after: {...}, <fn>: {...} }
def parse-snapshots []: string -> record {
    let records = $in | split row (char nul) | drop 1 | chunks 3
    let empty = { env: {}, shellvars: {} }
    let state = $records | reduce -f { current: $empty, snapshots: {} } {|r, acc|
        match $r.0 {
            'E' => ($acc | update current.env { insert $r.1 $r.2 })
            'S' => ($acc | update current.shellvars { insert $r.1 $r.2 })
            '-' => ($acc | update snapshots { insert $r.1 $acc.current } | update current $empty)
        }
    }
    $state.snapshots
}

# new/changed entries of $after relative to $before; entries gone are null
def diff [before: record, after: record]: nothing -> record {
    let changed = $after | transpose name value
        | where {|r| ($before | get -o $r.name) != $r.value }
    let unset = $before | columns
        | where {|n| $n not-in ($after | columns) }
        | each {|n| { name: $n, value: null } }
    $changed ++ $unset | reduce -f {} {|r, acc| $acc | insert $r.name $r.value }
}

def diff-snapshot [before: record, after: record]: nothing -> record {
    {
        env: (diff $before.env $after.env)
        shellvars: (diff $before.shellvars $after.shellvars)
    }
}

export def main [
    path?: string             # bash script to source; stdin is eval'd instead when omitted
    --shellvars (-s)          # structured output: {env, shellvars}
    --fn (-f): list<string> = []  # also invoke these shell functions and capture their effect
]: [string -> any, nothing -> any] {
    let path_args = if $path != null { [($path | path expand)] } else { [] }
    let fn_args = if ($fn | is-empty) { [] } else { ['--fn' ($fn | str join ',')] }
    let args = $path_args ++ $fn_args
    let input = $in | default '' | str join "\n"
    let res = $input | bash -c $script bash-env ...$args | complete
    if $res.exit_code != 0 {
        let msg = $res.stderr | lines | get -o 0 | default $"bash exited with ($res.exit_code)"
        error make -u { msg: $msg }
    }
    let out = if ($res.stdout | describe) == binary { $res.stdout | decode utf-8 } else { $res.stdout }
    let snaps = $out | parse-snapshots

    let result = diff-snapshot $snaps.before $snaps.after
    let result = if ($fn | is-empty) { $result } else {
        # each function's delta is relative to the snapshot taken just before it
        let fn_deltas = $fn | enumerate | reduce -f {} {|it, acc|
            let prev = if $it.index == 0 { $snaps.after } else { $snaps | get ($fn | get ($it.index - 1)) }
            $acc | insert $it.item (diff-snapshot $prev ($snaps | get $it.item))
        }
        $result | insert fn $fn_deltas
    }
    if $shellvars or ($fn | is-not-empty) { $result } else { $result.env }
}

# Apply the exported-variable delta to the current session: unsets variables
# the script unset and converts PATH-like strings back to nushell lists.
export def --env load [
    path?: string
]: [string -> nothing, nothing -> nothing] {
    let input = $in
    let vars = $input | main $path
    for r in ($vars | transpose name value) {
        if $r.value == null {
            hide-env -i $r.name
        } else {
            let conv = $env.ENV_CONVERSIONS | get -o $r.name
            let value = if $conv != null {
                do $conv.from_string $r.value
            } else if ($r.name in [PATH Path]) and (($env | get -o $r.name | describe) =~ '^list') {
                $r.value | split row (char esep)
            } else {
                $r.value
            }
            load-env { $r.name: $value }
        }
    }
}
