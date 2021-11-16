genpasswd() {
    strings /dev/urandom | grep -o '[[:alnum:]]' | head -n 14 | tr -d '\n'; echo
}

genpwentry() {
    read -sp "Passsord: " PW
    read -sp "Salt: " SALT
    export PW
    export SALT
    perl -e 'print crypt($ENV{PW},"\$6\$".$ENV{SALT}."\$") . "\n"'
    unset PW
    unset SALT
}

function docdate () {
  f="$1"
  d="${2:-now}"
  iso="$(date -d "$d" -Iseconds|sed -e 's/[-+][0-9]*$//')"
  unzip -p "$f" meta.xml |
  sed -e "s,<meta:creation-date>[^<]*,<meta:creation-date>${iso}," >meta.xml &&
  zip "$f" meta.xml
  rm -f meta.xml
}

alias llth='ls -lt | head'
alias unknown='ssh-keygen -R'

# -------
# ssh tunnel alias
# -------
alias sshtun='~/bin/ssh-tunnel-manager.sh --config ~/bin/ssh-tunnel-manager.conf'

# ----------------------
# Git Aliases
# ----------------------
alias ga='git add'
alias gaa='git add .'
alias gaaa='git add --all'
alias gau='git add --update'
alias gb='git branch'
alias gbd='git branch --delete '
alias gc='git commit'
alias gcm='git commit --message'
alias gcf='git commit --fixup'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gcom='git checkout master'
alias gcos='git checkout staging'
alias gcod='git checkout develop'
alias gd='git diff'
alias gda='git diff HEAD'
alias gi='git init'
alias glg='git log --graph --oneline --decorate --all'
alias gld='git log --pretty=format:"%h %ad %s" --date=short --all'
alias gm='git merge --no-ff'
alias gma='git merge --abort'
alias gmc='git merge --continue'
alias gp='git pull'
alias gpr='git pull --rebase'
alias gr='git rebase'
alias gs='git status'
alias gss='git status --short'
alias gst='git stash'
alias gsta='git stash apply'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gsts='git stash save'

# ----------------------
# Git Functions
# ----------------------
# Git log find by commit message
function glf() { git log --all --grep="$1"; }


gd() {
	    DIR=$HOME/git/${1}
	        cd ${DIR}
	}
complete -W "$(cd ~/git; for i in $(/bin/ls); do echo "$i"; done)" gd
