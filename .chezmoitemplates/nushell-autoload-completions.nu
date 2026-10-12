# Tab completion for external commands.
#
# Nushell ships no completions for externals (git, cargo, ros2, ...):
# $env.config.completions.external.completer is null by default, so <TAB>
# after an external command only offers file paths. Two sources are chained:
#
#   1. carapace (https://carapace.sh): git, cargo, docker, ... (~1000 commands).
#      env.nu generates its init script into ~/.cache/carapace/init.nu.
#   2. (Linux only) scripts/argcomplete.nu: python argcomplete CLIs, i.e. ros2
#      and colcon, which carapace does not cover. Needs the ROS env loaded.
#
# extern-based completions (chezmoi-completions.nu) take precedence: nushell
# only consults this completer for commands without a declared extern.

source ~/.cache/carapace/init.nu
{{- if eq .chezmoi.os "linux" }}
use argcomplete.nu
{{- end }}

let carapace_completer = $env.config.completions.external.completer

$env.config.completions.external.completer = {|spans|
    # Expand an alias to all of its words. carapace's init script only keeps
    # the first word, so `alias gs = git status` would be completed as `git`.
    let expansion = (scope aliases | where name == $spans.0 | $in.0?.expansion?)
    let spans = if $expansion != null {
        ($expansion | split row ' ') ++ ($spans | skip 1)
    } else {
        $spans
    }
{{- if eq .chezmoi.os "linux" }}

    let from_argcomplete = (argcomplete complete $spans)
    if $from_argcomplete != null {
        $from_argcomplete
    } else if $carapace_completer != null {
{{- else }}

    if $carapace_completer != null {
{{- end }}
        do $carapace_completer $spans
    } else {
        null  # nushell falls back to file path completion
    }
}
