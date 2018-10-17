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
