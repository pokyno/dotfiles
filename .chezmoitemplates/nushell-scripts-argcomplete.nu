# Tab completion for python argcomplete-based CLIs (ros2, colcon, ...).
#
# argcomplete has a simple protocol: run the program with _ARGCOMPLETE=1 and
# COMP_LINE/COMP_POINT set, and instead of running it prints its completions
# to fd 8. bash does the fd redirect since nushell has no syntax for fd 8.
#
# Wired into $env.config.completions.external.completer by
# autoload/completions.nu. The completed program must be on PATH with its
# python deps importable, i.e. the ROS environment must be loaded first.

# commands known to use python argcomplete
export const commands = [ros2 colcon]

# Completions for the given command-line spans, or null when the command is
# not an argcomplete one (null tells nushell to try the next completer).
export def complete [spans: list<string>]: nothing -> any {
    let cmd = ($spans | first)
    if $cmd not-in $commands { return null }

    let line = ($spans | str join " ")

    with-env {
        _ARGCOMPLETE: "1"
        _ARGCOMPLETE_IFS: "\n"
        _ARGCOMPLETE_SUPPRESS_SPACE: "1"  # bare values; trailing space added below
        COMP_LINE: $line
        COMP_POINT: ($line | str length | into string)
        COMP_TYPE: "9"
    } {
        ^bash -c $"'($cmd)' 8>&1 9>/dev/null 1>/dev/null 2>/dev/null"
        | lines
        | where { is-not-empty }
        | each {|v|
            # as in bash: keep typing after `--flag=` or `dir/`, otherwise the
            # argument is finished and the next one starts
            let value = if ($v | str ends-with '=') or ($v | str ends-with '/') {
                $v
            } else {
                $v + ' '
            }
            { value: $value, display: $v }
        }
    }
}
