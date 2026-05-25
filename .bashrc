# .bashrc

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
#HISTCONTROL=ignoreboth
export HISTCONTROL=erasedups
export HISTFILE=~/.bash_eternal_history

# export HISTTIMEFORMAT="%s "
export HISTTIMEFORMAT="[%F %T] "

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
#export HISTSIZE=1000
export HISTSIZE=
#export HISTFILESIZE=2000
export HISTFILESIZE=

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions

function ProgressBar {
# 1. Create ProgressBar function
# 1.1 Input is currentState($1) and totalState($2)
# Process data
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
# Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:
# 1.2.1.1 Progress : [########################################] 100%
    printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"

}

# eval "$(jump shell)"

#source ~/bin/command_prompt.sh

#function _update_ps1() { export PS1="$(/opt/Data/Personal/NextCloud/Documents/IT/repos/promptastic/promptastic.py $?)"; }

function _update_ps1() {
        #line="`printf -vch "%${COLUMNS}s" ""; printf "%s" "${ch// /-}"`"
        #dts="`date +"-- %Y-%b-%d %H:%M:%S "`"
        #export PS1='${dts}${line:${#dts}}\[\e[0m\]\r-(\[\e[0m\]\t\[\e[0m\])-(\[\e[0;36m\]\u\[\e[0;36m\]@\[\e[0;36m\]\h\[\e[0m\])-(\[\e[0;48;5;238m\]\w\[\e[0m\])-(\[\e[0;31m\]$?\[\e[0m\])-(\[\e[0;41m\]\[\e[1;41m\]$(git branch 2>/dev/null | grep '"'"'^*'"'"' | colrm 1 2)\[\e[0;41m\]\[\e[0m\])- \$\[\e[0m\] ';
#        export PS1='-(\[\e[0m\]\t\[\e[0m\])-(\[\e[0;36m\]\u\[\e[0;36m\]@\[\e[0;36m\]\h\[\e[0m\])-(\[\e[0;48;5;238m\]\w\[\e[0m\])-(\[\e[0;31m\]$?\[\e[0m\])-(\[\e[0;41m\]\[\e[1;41m\]$(git branch 2>/dev/null | grep '"'"'^*'"'"' | colrm 1 2)\[\e[0;41m\]\[\e[0m\])- \$\[\e[0m\] ';
        export PROMPT1='-(\[\e[0m\]\t\[\e[0m\])-(\[\e[0;36m\]\u\[\e[0;36m\]@\[\e[0;36m\]\h\[\e[0m\])-(\[\e[0;48;5;238m\]\w\[\e[0m\])-(\[\e[0;31m\]$?\[\e[0m\])-(\[\e[0;41m\]\[\e[1;41m\]$(git branch 2>/dev/null | grep '"'"'^*'"'"' | colrm 1 2)\[\e[0;41m\]\[\e[0m\])- \$\[\e[0m\] ';
	# PS1='+-\[\e[38;5;39m\][\u from \h][\D{%Y-%m-%d at }\t]\n+-[\[\e[38;5;43m\]\w\[\e[38;5;39m\]]\n\$\[\e[0m\] '
	# PROMPT_COMMAND='PS1_CMD1=$(__git_ps1 " (%s)")'; PS1='\[\e[38;5;39m\]+-\[\e[38;5;33m\][\[\e[38;5;39m\]\u from \h][\D{%Y-%m-%d at }\t]\n+-[\[\e[38;5;43m\]\w\[\e[38;5;39m\]]\[\e[0m\]${PS1_CMD1}\n\[\e[38;5;39m\]\$\[\e[0m\] '
}


#export PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
# export PROMPT_COMMAND="_update_ps1; history -a >> $HISTFILE; $PROMPT_COMMAND"
# export PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND; echo $$ $USER $(history 1) >> ~/.bash_eternal_history"

# EBD 2024-02-24 setting chattr +a on ~/.bash_history to let bash do it's thing
#                turning off the eternal history for now
#PROMPT_COMMAND="_update_ps1; ${PROMPT_COMMAND:+$PROMPT_COMMAND}"'echo $$ $USER \
#	               "$(history 1)" >> ~/.bash_eternal_history'
# PROMPT_COMMAND="_update_ps1; history -a; history -c; history -r; ${PROMPT_COMMAND:+$PROMPT_COMMAND}"
PROMPT_COMMAND="history -a; history -c; history -r; ${PROMPT_COMMAND:+$PROMPT_COMMAND}"

#if [ -f "/opt/Data/Personal/repos/bash-git-prompt/gitprompt.sh" ]; then
#	GIT_PROMPT_ONLY_IN_REPO=1
#	source /opt/Data/Personal/repos/bash-git-prompt/gitprompt.sh
#fi

[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh

# setup atuin (history search from SQLITE DB)
# curl https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh -o ~/.bash-preexec.sh
# echo '[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh' >> ~/.bashrc
#eval "$(atuin init bash)"


# if test -n "$DESKTOP_SESSION"
# 	set -x $(gnome-keyring-daemon--start | string split "=")
# fi

# eval "$($HOME/bin/oh-my-posh init bash --config ~/.poshthemes/ys.omp.json)"
# eval "$($HOME/bin/oh-my-posh init bash --config ~/.poshthemes/stelbent.minimal.omp.json)"
# eval "$($HOME/bin/oh-my-posh init bash --config ~/.poshthemes/tokyo.omp.json)"
# eval "$($HOME/bin/oh-my-posh init bash --config ~/.poshthemes/probua.minimal.omp.json)"
# eval "$($HOME/bin/oh-my-posh init bash --config ~/.poshthemes/onehalf.minimal.omp.json)"
eval "$($HOME/bin/oh-my-posh init bash --config ~/.poshthemes/ebd.minimal.omp.json)"

# eval "$($HOME/bin/fasd --init auto)"

## Directory aliases
export NC=/opt/Data/Personal/NextCloud
export NCIT=/opt/Data/Personal/NextCloud/Documents/IT
export NCITC=/opt/Data/Personal/NextCloud/Documents/IT\ Clients
export CI=/opt/Data/Cisco
export CID=/opt/Data/Cisco/Dev


## docker compose aliases from https://perfectmediaserver.com
# Tail last 50 lines of docker logs
alias dtail='docker logs -tf --tail='50' '

# Shorthand, customise docker-compose.yaml location as needed
# alias dcp='docker-compose -f ~/docker-compose.yaml '
alias dcp='docker-compose -f ./docker-compose.yaml '

# Remove unused images (useful after an upgrade)
alias dprune='docker image prune'

# Remove unused images, unused networks *and data* (use with care)
# alias dprunesys='docker system prune --all'

export LIBVA_DRIVER_NAME=iHD

PATH="${PATH:+:${PATH}}"; export PATH;
export PATH=$PATH:$HOME/bin

# git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

#export JAVA_HOME=$(dirname $(dirname $(readlink $(readlink $(which javac)))))
#export PATH=$PATH:$JAVA_HOME/bin:$HOME/bin
#export CLASSPATH=.:$JAVA_HOME/jre/lib:$JAVA_HOME/lib:$JAVA_HOME/lib/tools.jar


# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi

unset rc


[ -r "$HOME/.smartcd_config" ] && ( [ -n $BASH_VERSION ] || [ -n $ZSH_VERSION ] ) && source ~/.smartcd_config

# from https://bash-prompt-generator.org/
# PS1='+-\[\e[38;5;39m\][\u from \h][\D{%Y-%m-%d at }\t]\n+-[\[\e[38;5;43m\]\w\[\e[38;5;39m\]]\n\$\[\e[0m\] '
# PROMPT_COMMAND='PS1_CMD1=$(__git_ps1 " (%s)")'; PS1='\[\e[38;5;39m\]+-\[\e[38;5;33m\][\[\e[38;5;39m\]\u from \h][\D{%Y-%m-%d at }\t]\n+-[\[\e[38;5;43m\]\w\[\e[38;5;39m\]]\[\e[0m\]${PS1_CMD1}\n\[\e[38;5;39m\]\$\[\e[0m\] '


