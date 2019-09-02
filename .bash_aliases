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

