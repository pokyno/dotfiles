# Custom completions for chezmoi.
# chezmoi (https://chezmoi.io) ships bash/fish/zsh/powershell completions but
# not nushell, so this module hand-rolls extern declarations for the common
# subcommands. Subcommand definitions are merged with the top-level extern by
# the nushell completer.

def "nu-complete chezmoi commands" [] {
    [
        { value: "add",              description: "Add an existing file, directory, or symlink to the source state" }
        { value: "apply",            description: "Update the destination directory to match the target state" }
        { value: "archive",          description: "Generate a tar archive of the target state" }
        { value: "cat",              description: "Print the target contents of a file or symlink" }
        { value: "cat-config",       description: "Print the configuration file" }
        { value: "cd",               description: "Launch a shell in the source directory" }
        { value: "chattr",           description: "Change the attributes of a target in the source state" }
        { value: "completion",       description: "Generate shell completion code" }
        { value: "data",             description: "Print the template data" }
        { value: "decrypt",          description: "Decrypt files or stdin" }
        { value: "diff",             description: "Print the diff between the target and destination state" }
        { value: "doctor",           description: "Check your system for potential problems" }
        { value: "dump",             description: "Generate a dump of the target state" }
        { value: "dump-config",      description: "Dump the configuration values" }
        { value: "edit",             description: "Edit the source state of a target" }
        { value: "edit-config",      description: "Edit the configuration file" }
        { value: "edit-config-template", description: "Edit the configuration file template" }
        { value: "encrypt",          description: "Encrypt files or stdin" }
        { value: "execute-template", description: "Execute a template" }
        { value: "forget",           description: "Remove a target from the source state" }
        { value: "generate",         description: "Generate a file for use with chezmoi" }
        { value: "git",              description: "Run git in the source directory" }
        { value: "ignored",          description: "List ignored targets" }
        { value: "init",             description: "Set up the source directory and update the destination" }
        { value: "managed",          description: "List the managed entries in the destination directory" }
        { value: "merge",            description: "Perform a three-way merge between destination, source, and target" }
        { value: "merge-all",        description: "Perform a three-way merge for each modified file" }
        { value: "purge",            description: "Purge chezmoi's configuration and data" }
        { value: "re-add",           description: "Re-add modified files" }
        { value: "remove",           description: "Remove targets from source and destination" }
        { value: "rm",               description: "Alias for remove" }
        { value: "secret",           description: "Interact with a secret manager" }
        { value: "source-path",      description: "Print the source path of a target" }
        { value: "state",            description: "Manipulate the persistent state" }
        { value: "status",           description: "Show the status of targets" }
        { value: "target-path",      description: "Print the target path of a source path" }
        { value: "unmanaged",        description: "List the unmanaged files in the destination directory" }
        { value: "update",           description: "Pull and apply changes" }
        { value: "upgrade",          description: "Upgrade chezmoi" }
        { value: "verify",           description: "Exit with success if the destination matches the target state" }
    ]
}

# Returns absolute paths chezmoi currently manages, suitable for completing
# arguments to apply/diff/cat/forget/edit/re-add.
def "nu-complete chezmoi managed" [] {
    let home = $nu.home-path
    chezmoi managed | lines | each {|l| ([$home $l] | path join) }
}

# --- root command ---
export extern "chezmoi" [
    command?: string@"nu-complete chezmoi commands"
    --source(-S): path     # Source directory
    --destination(-D): path # Destination directory
    --config(-c): path     # Config file
    --dry-run(-n)          # Do not make any modifications
    --verbose(-v)          # Verbose
    --force                # Make all changes without prompting
    --keep-going(-k)       # Keep going on error
    --debug                # Include debug information in output
    --no-pager             # Do not use a pager
    --no-tty               # Do not attach a TTY
    --help(-h)             # Help
]

# --- frequent subcommands (extern names beginning with "chezmoi " merge) ---
export extern "chezmoi add" [
    ...paths: path
    --autotemplate          # Add files as templates with auto detection
    --create                # Add files as create_ entries
    --empty(-e)             # Add empty files
    --encrypt               # Encrypt files
    --exact                 # Add directories with the exact attribute
    --follow(-f)            # Add symlink targets, not symlinks
    --include(-i): string   # Include only types
    --exclude(-x): string   # Exclude types
    --prompt(-p)            # Prompt before adding
    --quiet(-q)             # Suppress messages
    --recursive(-r)         # Recurse into subdirectories
    --secrets: string       # Secret handling: error, warning, ignore
    --template(-T)          # Add files as templates
    --template-symlinks     # Add symlinks as templates
]

export extern "chezmoi apply" [
    ...targets: string@"nu-complete chezmoi managed"
    --include(-i): string
    --exclude(-x): string
    --recursive(-r)
    --init                  # Recreate config file from template
]

export extern "chezmoi diff" [
    ...targets: string@"nu-complete chezmoi managed"
    --include(-i): string
    --exclude(-x): string
    --recursive(-r)
    --reverse
    --parent-dirs(-P)
    --script-contents
    --init
]

export extern "chezmoi cat" [
    ...targets: string@"nu-complete chezmoi managed"
]

export extern "chezmoi edit" [
    ...targets: string@"nu-complete chezmoi managed"
    --apply                 # Apply target after editing
    --hardlink              # Hardlink files instead of copying
    --watch                 # Apply changes when files are saved
]

export extern "chezmoi forget" [
    ...targets: string@"nu-complete chezmoi managed"
    --recursive(-r)
]

export extern "chezmoi re-add" [
    ...targets: string@"nu-complete chezmoi managed"
    --include(-i): string
    --exclude(-x): string
    --recursive(-r)
]

export extern "chezmoi status" [
    ...targets: string@"nu-complete chezmoi managed"
    --include(-i): string
    --exclude(-x): string
    --recursive(-r)
]

export extern "chezmoi verify" [
    ...targets: string@"nu-complete chezmoi managed"
    --include(-i): string
    --exclude(-x): string
    --recursive(-r)
]

export extern "chezmoi managed" [
    --include(-i): string
    --exclude(-x): string
    --path-style: string    # absolute, relative, source-absolute, source-relative, target
    --tree(-t)
]

export extern "chezmoi unmanaged" [
    ...paths: path
    --path-style: string
]

export extern "chezmoi completion" [
    shell: string@"nu-complete chezmoi completion-shells"
    --output(-o): path
]

def "nu-complete chezmoi completion-shells" [] {
    [ "bash" "fish" "powershell" "zsh" ]
}

export extern "chezmoi git" [
    ...args
]

export extern "chezmoi update" [
    --apply                 # Apply after pulling
    --recursive(-r)
]
