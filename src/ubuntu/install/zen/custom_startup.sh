#!/usr/bin/env bash
# Kasm startup script for Zen Browser. Keeps the browser alive (auto-restarts
# if it exits), maximizes the window and honors a KASM_URL / LAUNCH_URL to
# open a specific page on first start. Mirrors the base-image convention so
# Kasm's "go/assign" exec mode also works when launching URLs post-startup.
set -ex
START_COMMAND="/opt/zen/zen"
PGREP="zen-bin"
PGREP_ALT="zen"
# Kasm's maximize_window.sh targets a window title; must match the browser's
export MAXIMIZE="true"
export MAXIMIZE_NAME="Zen"
MAXIMIZE_SCRIPT=$STARTUPDIR/maximize_window.sh
DEFAULT_ARGS=""
ARGS=${APP_ARGS:-$DEFAULT_ARGS}

# Standard Kasm single-app option parsing: -g/--go, -a/--assign, -u/--url
options=$(getopt -o gau: -l go,assign,url: -n "$0" -- "$@") || exit
eval set -- "$options"

while [[ $1 != -- ]]; do
    case $1 in
        -g|--go) GO='true'; shift 1;;
        -a|--assign) ASSIGN='true'; shift 1;;
        -u|--url) OPT_URL=$2; shift 2;;
        *) echo "bad option: $1" >&2; exit 1;;
    esac
done
shift

# Process non-option arguments.
for arg; do
    echo "arg! $arg"
done

FORCE=$2

# run with vgl if GPU is available (Kasm's VirtualGL passthrough)
if [ -f /opt/VirtualGL/bin/vglrun ] && [ ! -z "${KASM_EGL_CARD}" ] && [ ! -z "${KASM_RENDERD}" ] && [ -O "${KASM_RENDERD}" ] && [ -O "${KASM_EGL_CARD}" ] ; then
    START_COMMAND="/opt/VirtualGL/bin/vglrun -d ${KASM_EGL_CARD} $START_COMMAND"
fi

# Launch a URL into the already-running browser (Kasm "go" / "assign" mode)
kasm_exec() {
    if [ -n "$OPT_URL" ] ; then
        URL=$OPT_URL
    elif [ -n "$1" ] ; then
        URL=$1
    fi

    # Since we are execing into a container that already has the browser running from startup,
    #  when we don't have a URL to open we want to do nothing. Otherwise a second browser instance would open.
    if [ -n "$URL" ] ; then
        /usr/bin/filter_ready
        /usr/bin/desktop_ready
        bash ${MAXIMIZE_SCRIPT} &
        $START_COMMAND $ARGS $OPT_URL
    else
        echo "No URL specified for exec command. Doing nothing."
    fi
}

# Main container startup path: keep the browser running forever
kasm_startup() {
    if [ -n "$KASM_URL" ] ; then
        URL=$KASM_URL
    elif [ -z "$URL" ] ; then
        URL=$LAUNCH_URL
    fi

    if [ -z "$DISABLE_CUSTOM_STARTUP" ] ||  [ -n "$FORCE" ] ; then

        echo "Entering process startup loop"
        set +x
        # Restart the browser whenever it dies so the session is never empty
        while true
        do
            if ! pgrep -x $PGREP > /dev/null && ! pgrep -x $PGREP_ALT > /dev/null
            then
                /usr/bin/filter_ready
                /usr/bin/desktop_ready
                set +e
                bash ${MAXIMIZE_SCRIPT} &
                $START_COMMAND $ARGS $URL
                set -e
            fi
            sleep 1
        done
        set -x

    fi

}

if [ -n "$GO" ] || [ -n "$ASSIGN" ] ; then
    kasm_exec
else
    kasm_startup
fi