#!/bin/bash

##########################################################
# Gruvbox-Dark Prompt (rbash-safe, ASCII-only)
##########################################################

#=========================================================
# Gruvbox ANSI Colors
#=========================================================
WHITE='\[\033[1;37m\]'        # bright fg (fg0)
LIGHTGRAY='\[\033[0;37m\]'    # fg2/fg3
GRAY='\[\033[1;30m\]'         # dimmer fg4
RED='\[\033[0;31m\]'          # red
LIGHTRED='\[\033[1;31m\]'     # bright red
GREEN='\[\033[0;32m\]'        # green
LIGHTGREEN='\[\033[1;32m\]'   # bright green
BROWN='\[\033[0;33m\]'        # orange
YELLOW='\[\033[1;33m\]'       # bright yellow
BLUE='\[\033[0;34m\]'         # blue
LIGHTBLUE='\[\033[1;34m\]'    # bright blue
PURPLE='\[\033[0;35m\]'       # purple
CYAN='\[\033[0;36m\]'         # aqua
DEFAULT='\[\033[0m\]'

#=========================================================
# Gruvbox color mapping
#=========================================================
cLINES=$LIGHTGRAY
cBRACKETS=$LIGHTGRAY
cERROR=$RED
cSUCCESS=$GREEN
cTIME=$WHITE
cMPX1=$YELLOW
cMPX2=$RED
cBGJ1=$YELLOW
cBGJ2=$RED
cSTJ1=$YELLOW
cSTJ2=$RED
cSSH=$PURPLE
cUSR=$LIGHTBLUE
cUHS=$CYAN
cHST=$LIGHTGREEN
cRWN=$BROWN
cPWD=$BLUE
cCMD=$DEFAULT

#=========================================================
# Feature toggles
#=========================================================
eNL=1
eERR=1
eTIME=1
eMPX=1
eSSH=1
eBGJ=1
eSTJ=1
eHOST=1
ePWD=1

MPXT1="0"
MPXT2="2"
BGJT1="0"
BGJT2="2"
STJT1="0"
STJT2="2"
UHS="@"

##########################################################
# rbash-safe check for command
##########################################################
cmd_exists() {
    type "$1" >/dev/null 2>&1
}

##########################################################
# rbash-safe count for tmux/screen
##########################################################
count_multiplexers() {
    local count=0

    # screen
    if cmd_exists screen; then
        count_screen=$(screen -ls 2>&1 | grep -c -i detach)
        count=$((count + count_screen))
    fi

    # tmux
    if cmd_exists tmux; then
        count_tmux=$(tmux ls 2>&1 | grep -c -i -v attached)
        count=$((count + count_tmux))
    fi

    echo "$count"
}

##########################################################
# PROMPT FUNCTION
##########################################################
promptcmd() {
    PREVRET=$?

    # SSH detection
    if [[ $SSH_CLIENT ]] || [[ $SSH2_CLIENT ]]; then
        lSSH_FLAG=1
    else
        lSSH_FLAG=0
    fi

    # newline
    if [ $eNL -eq 1 ]; then
        PS1="\n"
    else
        PS1=""
    fi

    ##########################################################
    # ASCII start: "|--"
    ##########################################################
    PS1="${PS1}${cLINES}|--"

    ##########################################################
    # Error/Success block
    ##########################################################
    if [ $eERR -eq 1 ]; then
        if [ $PREVRET -ne 0 ]; then
            PS1="${PS1}${cBRACKETS}[${cERROR}:(${cBRACKETS}]${cLINES}--"
        else
            PS1="${PS1}${cBRACKETS}[${cSUCCESS}:)${cBRACKETS}]${cLINES}--"
        fi
    fi

    ##########################################################
    # Time block
    ##########################################################
    if [ $eTIME -eq 1 ]; then
        PS1="${PS1}${cBRACKETS}[${cTIME}\t${cBRACKETS}]${cLINES}--"
    fi

    ##########################################################
    # Multiplexer count
    ##########################################################
    if [ $eMPX -eq 1 ]; then
        MPXC=$(count_multiplexers)
        if [ "$MPXC" -gt "$MPXT2" ]; then
            PS1="${PS1}${cBRACKETS}[${cMPX2}M:${MPXC}${cBRACKETS}]${cLINES}--"
        elif [ "$MPXC" -gt "$MPXT1" ]; then
            PS1="${PS1}${cBRACKETS}[${cMPX1}M:${MPXC}${cBRACKETS}]${cLINES}--"
        fi
    fi

    ##########################################################
    # Background jobs
    ##########################################################
    if [ $eBGJ -eq 1 ]; then
        BGJC=$(jobs -r | wc -l)
        if [ "$BGJC" -gt "$BGJT2" ]; then
            PS1="${PS1}${cBRACKETS}[${cBGJ2}&:${BGJC}${cBRACKETS}]${cLINES}--"
        elif [ "$BGJC" -gt "$BGJT1" ]; then
            PS1="${PS1}${cBRACKETS}[${cBGJ1}&:${BGJC}${cBRACKETS}]${cLINES}--"
        fi
    fi

    ##########################################################
    # Stopped jobs
    ##########################################################
    if [ $eSTJ -eq 1 ]; then
        STJC=$(jobs -s | wc -l)
        if [ "$STJC" -gt "$STJT2" ]; then
            PS1="${PS1}${cBRACKETS}[${cSTJ2}S:${STJC}${cBRACKETS}]${cLINES}--"
        elif [ "$STJC" -gt "$STJT1" ]; then
            PS1="${PS1}${cBRACKETS}[${cSTJ1}S:${STJC}${cBRACKETS}]${cLINES}--"
        fi
    fi

    ##########################################################
    # User@host
    ##########################################################
    if [ $lSSH_FLAG -eq 1 ]; then
        sesClr="$cSSH"
    else
        sesClr="$cBRACKETS"
    fi

    if [ $EUID -eq 0 ]; then
        PS1="${PS1}${sesClr}[${cRWN}!${cHST}\h${sesClr}]${cLINES}--"
    else
        PS1="${PS1}${sesClr}[${cUSR}\u${cUHS}${UHS}${cHST}\h${sesClr}]${cLINES}--"
    fi

    ##########################################################
    # Directory
    ##########################################################
    if [ $ePWD -eq 1 ]; then
        PS1="${PS1}${cBRACKETS}[${cPWD}\w${cBRACKETS}]"
    fi

    ##########################################################
    # Second line: "|-->"
    ##########################################################
    PS1="${PS1}\n${cLINES}|--> ${cCMD}"
}

##########################################################
# Install prompt
##########################################################
PROMPT_COMMAND=promptcmd
export PS1 PROMPT_COMMAND
echo -ne "\e[5 q"
