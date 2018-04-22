#!/usr/bin/env bash

CONFIG="$HOME/.config/spinner"          # Default configuration directory.
CONFIG_FILE="$CONFIG/config"            # Default configuration file.
SPINNERS_FILE="$CONFIG/spinners.json"   # Default location of spinners file.
NAME="dots"                             # Default spinner name.
HELP="""\
spinner [OPTIONS...] [COMMANDS...]

Display a loading spinner while a command runs.

Options:
  -f    Specify a path to an alternate JSON file of spinners to use.
  -s    Specify the name of the spinner to display.

Commands:
  -h    Show this help text
"""

function show_spinner {
    local spinner=$(jq ".$NAME" "$SPINNERS_FILE")
    if [[ "$spinner" = "null" ]]; then
        (>&2 echo "$0: Was unable to load spinner $NAME.")
        exit 1
    fi

    local spinner_interval=$(jq ".interval" <<< "$spinner" )
    if [[ "$spinner_interval" = "null" ]]; then
        (>&2 echo "$0: Was unable to load spinner interval for $NAME.")
        exit 1
    fi
    local delay=$(bc -l <<< "$spinner_interval/1000")

    local frames_string=$(jq -r '.frames[]' <<<"$spinner")
    if [[ "$frames_string" = "null" ]]; then
        (>&2 echo "$0: Was unable to load frames for $NAME.")
        exit 1
    fi

    readarray -t frames <<< "$frames_string"
    while true; do
        for frame in "${frames[@]}"; do
            printf "\r $frame  "
            sleep "$delay"
        done
    done
}

function usage {
    less -FRSXMK <<< $HELP || more <<< $HELP || cat <<< $HELP
}

function sigint {
    echo "Received SIGINT. Shutting down $GIVEN_PROC."
    kill -2 "$GIVEN_PROC"
    kill -2 "$SPINNER_PROC" 2>/dev/null
}

function sigquit {
    echo "Received SIGQUIT. Shutting down $GIVEN_PROC."
    kill -3 "$GIVEN_PROC"
    kill -3 "$SPINNER_PROC" 2>/dev/null
}

function main {
    trap 'sigint'  SIGINT
    trap 'sigquit' SIGQUIT

    tput civis # Hide cursor.
    show_spinner &
    SPINNER_PROC=$!

    ($@) &
    GIVEN_PROC=$!

    wait "$GIVEN_PROC"
    { kill "$SPINNER_PROC" && wait "$SPINNER_PROC"; } 2>/dev/null
    tput cvvis # Make cursor visible again.
    printf "\n"
}

# Handle arguments.
while getopts "f:s:h" opt; do
    case ${opt} in
        f) SPINNERS_FILE=${OPTARG} ;;
        s) NAME=${OPTARG} ;;
        h) usage; exit ;;
    esac
done
shift $((OPTIND -1))


if [ ! -d "$CONFIG" ]; then
    echo "Creating default configuration directory at $CONFIG."
    echo "This message will not be present next time you run."
    mkdir $CONFIG
fi


if [[ ! -f $SPINNERS_FILE ]]; then
    echo "Fetching default set of spinners to $CONFIG."
    echo "This message will not be present next time you run."
    wget -q -P "$CONFIG" "https://raw.githubusercontent.com/sindresorhus/cli-spinners/master/spinners.json"
fi


main $@
