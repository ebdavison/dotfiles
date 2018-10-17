genpasswd() {
    strings /dev/urandom | grep -o '[[:alnum:]]' | head -n 14 | tr -d '\n'; echo
}

genpwentry() {
    read -p "Passsord: " PW
    read -p "Salt: " SALT
    #echo "${PW} ${SALT}"
    export PW
    export SALT
    perl -e 'print $ENV{PW} . "\n" . $ENV{SALT} . "\n" . crypt($ENV{PW},"\$6\$".
$ENV{SALT}."\$") . "\n"'
    unset PW
    unset SALT
}
