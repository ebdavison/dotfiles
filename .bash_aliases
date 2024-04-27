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

# -------
# ssh tunnel alias
# -------
alias sshtun='~/bin/ssh-tunnel-manager.sh --config ~/bin/ssh-tunnel-manager.conf'

# --------
# cisco specific
# --------
alias awsjump='ssh -J heimdall -A ${1}'
alias gitlab='ssh -i ~/.ssh/id_rsa -T -L 8088:gitlab.tgsre.net:8088 eddaviso@34.197.225.206'
alias gitlabssh='ssh -i ~/.ssh/id_rsa -T -L 20022:gitlab.tgsre.net:22 eddaviso@34.197.225.206'
alias esm1='ssh -i ~/.ssh/id_rsa -T -L 29200:es-master-1.tgsre.net:9200 eddaviso@34.197.225.206'
alias esk1='ssh -i ~/.ssh/id_rsa -T -L 25601:es-master-1.tgsre.net:5601 eddaviso@34.197.225.206'
alias mount_ui01fs='sshfs -o idmap=user eddaviso@hunt-ui-01.clg5.amp.ciscolabs.com: /opt/Data/Cisco/mounts/hunt-ui-01'


# local directory aliases
alias cd-ci="cd /opt/Data/Cisco"
alias cd-ne="cd /opt/Data/Personal/NextCloud"
alias cd-it="cd /opt/Data/Personal/NextCloud/Documents/IT"
alias cd-fi="cd /opt/Data/Personal/NextCloud/Documents/Finance"
alias cd-acct="cd /opt/Data/Personal/NextCloud/Documents/Finance/accounting"
alias cd-itc="cd /opt/Data/Personal/NextCloud/Documents/IT\ Clients"
alias cd-rpg="cd /opt/Data/Personal/NextCloud/Documents/IT\ Clients/RPG"
alias cd-so="cd /opt/Data/Software"

#alias tmux="tmux -u"
alias tmux="tmux -u"
#alias tmux="systemd-run --scope --user tmux -u "

# docker related
# # get all docker IPs
alias dcips=$'docker inspect -f \'{{.Name}}-{{range  $k, $v := .NetworkSettings.Networks}}{{$k}}-{{.IPAddress}} {{end}}-{{range $k, $v := .NetworkSettings.Ports}}{{ if not $v }}{{$k}} {{end}}{{end}} -{{range $k, $v := .NetworkSettings.Ports}}{{ if $v }}{{$k}} => {{range . }}{{ .HostIp}}:{{.HostPort}}{{end}}{{end}} {{end}}\' $(docker ps -aq) | column -t -s-'
# docker compose shortcut alias
alias dcp='docker-compose -f ~/docker-compose.yml '
# Tail last 50 lines of docker logs
alias dtail='docker logs -tf --tail='50' '

# Remove unused images (useful after an upgrade)
alias dprune='docker image prune'

# Remove unused images, unused networks *and data* (use with care)
alias dprunesys='docker system prune --all'


alias lth='ls -alt | head'
alias llt='ls -alt'
alias lthh='ls -alth | head'

alias dm='sudo dmesg --time-format iso'

