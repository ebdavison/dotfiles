#!/bin/sh
# run webex client via systemd-run to limit its resources.
#  log:    journalctl --user --unit=webex-teams
#  status: systemctl --user status webex-teams
#
# webex client for linux is at
# https://wiki.cisco.com/display/WX2/Linux+Client+Internal+Testing
#

# Scott Moser 4/26/22 9:29 AM • 
# FWIW, I use systemd-run to launch webex with --property=MemoryLimit=4G. It
# doesn't "fix" the problem, but it does mean that rather than my desktop
# freezing up for a few minutes as OOM operates, its just webex that is
# affected by its leakage.

name="webex-teams"
prog="/opt/Webex/bin/CiscoCollabHost"
mem="2G"
out=$(systemctl --user is-active "$name")
rc=$?
error=false
case "$rc" in
    3|0) :
        case "$out" in
            # if active, restart it by stopping here and starting below.
            active)
                systemctl --user stop "$name" ||
                    { echo "stop $name failed"; exit 1; };;
            failed)
                systemctl --user reset-failed "$name" ||
                    { echo "reset-failed $name failed"; exit 1; };;
            inactive)
		:;;
            *)
		error=true;;
        esac
        ;;
    *) error=true;;
esac

if [ "$error" = "true" ]; then
    echo "'systemctl --user is-active $name'" \
        "exited $rc with unexpected output: $out" 1>&2
    exit 9
fi

set -- systemd-run --user \
    "--remain-after-exit" \
    "--property=MemoryLimit=$mem" "--unit=$name" "$prog"

exec "$@"
