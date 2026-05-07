# env.nu
#
# version = "0.109.1"
#
# Loaded before config.nu and any autoload module is parsed. Use it to
# create files that later modules will `source`, since nushell's `source`
# is a parse-time keyword and parses the whole module before running it.

# zoxide.nu must exist before autoload/cd-zoxide.nu is parsed; the install
# script normally writes it, but generate it here too as a safety net for
# fresh shells where the install script hasn't run.
if not ('~/.zoxide.nu' | path expand | path exists) {
    if (which zoxide | is-not-empty) {
        zoxide init nushell | save -f ~/.zoxide.nu
    } else {
        '' | save -f ~/.zoxide.nu
    }
}
