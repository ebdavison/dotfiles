genpasswd() {
    strings /dev/urandom | grep -o '[[:alnum:]]' | head -n 14 | tr -d '\n'; echo
}
