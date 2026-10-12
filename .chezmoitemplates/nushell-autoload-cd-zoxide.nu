# `source` is parse-time, so ~/.zoxide.nu must exist and define __zoxide_z
# before this file is parsed. env.nu guarantees that (and puts ~/.cargo/bin on
# PATH so `zoxide` itself resolves at runtime).
source ~/.zoxide.nu
alias cd = __zoxide_z
