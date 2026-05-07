# Gruvbox-dark two-line prompt mirroring ~/.config/bash/prompt.sh.
# ASCII-only; ANSI color choices match the bash version 1:1.

def __prompt-mpx-count [] {
    mut n = 0
    if (which tmux | is-not-empty) {
        try { $n = $n + (^tmux ls e>| ignore | lines | where {|l| not ($l =~ "attached") } | length) }
    }
    if (which screen | is-not-empty) {
        try { $n = $n + (^screen -ls e>| ignore | lines | where {|l| $l =~ "Detach"} | length) }
    }
    $n
}

def __prompt-bg-jobs [] {
    try { (job list | length) } catch { 0 }
}

def __prompt-line [] {
    # bash mapping (see ~/.config/bash/prompt.sh):
    #   LIGHTGRAY=0;37  WHITE=1;37  RED=0;31  GREEN=0;32  BROWN=0;33
    #   YELLOW=1;33  BLUE=0;34  LIGHTBLUE=1;34  LIGHTGREEN=1;32
    #   CYAN=0;36  PURPLE=0;35
    # Brackets, lines, dashes, the |--> arrow, and the SSH bracket are
    # rendered NON-bold so they recede; data (time/user/@/host/path) and
    # the smile/frown/threshold warnings are rendered BOLD so they pop.
    let cBR    = (ansi white)        # 0;37 lines/brackets/arrow
    let cFG    = (ansi white_bold)   # 1;37 time
    let cOK    = (ansi green_bold)   # 1;32 :)
    let cERR   = (ansi red_bold)     # 1;31 :( and over-thresholds
    let cYEL   = (ansi yellow_bold)  # 1;33 first-threshold warning
    let cLBL   = (ansi blue_bold)    # 1;34 user
    let cBLUE  = (ansi blue_bold)    # 1;34 path
    let cLGN   = (ansi green_bold)   # 1;32 host
    let cCYN   = (ansi cyan_bold)    # 1;36 @
    let cPUR   = (ansi purple)       # 0;35 ssh bracket (still non-bold; it's a bracket)
    let cBRN   = (ansi yellow_bold)  # 1;33 root warning
    let r      = (ansi reset)

    let exit = ($env.LAST_EXIT_CODE? | default 0 | into int)
    let smile = ":)"
    let frown = ":("
    let face = (if $exit == 0 { $cOK + $smile } else { $cERR + $frown })

    let now  = (date now | format date "%H:%M:%S")
    let user = ($env.USER? | default ($env.USERNAME? | default "user"))
    let host = (try { sys host | get hostname } catch { "host" })

    let ssh = ((($env.SSH_CLIENT? | default "") != "") or (($env.SSH_TTY? | default "") != ""))
    let sclr = (if $ssh { $cPUR } else { $cBR })

    let mpx = (__prompt-mpx-count)
    let bgj = (__prompt-bg-jobs)

    let mpx_block = (if $mpx > 2 {
        $"($cBR)[($cERR)M:($mpx)($cBR)]($cBR)--"
    } else if $mpx > 0 {
        $"($cBR)[($cYEL)M:($mpx)($cBR)]($cBR)--"
    } else { "" })

    let bgj_block = (if $bgj > 2 {
        $"($cBR)[($cERR)&:($bgj)($cBR)]($cBR)--"
    } else if $bgj > 0 {
        $"($cBR)[($cYEL)&:($bgj)($cBR)]($cBR)--"
    } else { "" })

    let user_host = (if (is-admin) {
        $"($sclr)[($cBRN)!($cLGN)($host)($sclr)]($cBR)--"
    } else {
        $"($sclr)[($cLBL)($user)($cCYN)@($cLGN)($host)($sclr)]($cBR)--"
    })

    let pwd_block = $"($cBR)[($cBLUE)($env.PWD)($cBR)]"

    # Bash puts both lines of the prompt in PS1; reedline does not render a
    # leading newline in PROMPT_INDICATOR reliably, so build the second line
    # here. PROMPT_INDICATOR is only used for vi-mode glyph swapping.
    $"\n($cBR)|--($cBR)[($face)($cBR)]($cBR)--($cBR)[($cFG)($now)($cBR)]--($mpx_block)($bgj_block)($user_host)($pwd_block)\n($cBR)|--> ($r)"
}

$env.PROMPT_COMMAND = { || __prompt-line }
$env.PROMPT_COMMAND_RIGHT = ""
$env.PROMPT_INDICATOR = ""
$env.PROMPT_INDICATOR_VI_INSERT = ""
$env.PROMPT_INDICATOR_VI_NORMAL = $"(ansi white)<= (ansi reset)"
