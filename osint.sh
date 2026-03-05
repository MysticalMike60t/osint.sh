#!/usr/bin/env bash

export PATH="$PATH"

if [ -z "${BASH_VERSION:-}" ]; then
    if ! exec /usr/bin/env bash "$0" "$@"; then
        echo "You need to use bash to run this script."
        exit 1
    fi
fi

# ----------------------------------------- #
#               Bash env init               #
# ----------------------------------------- #

set -e

# ----------------------------------------- #
#             End Bash env init             #
# ----------------------------------------- #

# ----------------------------------------- #
#          Ask for admin privledges         #
# ----------------------------------------- #

if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
    exit $?
fi

# ----------------------------------------- #
#        End Ask for admin privledges       #
# ----------------------------------------- #

# --> GENERATED CODE <-- #

# OS / System info vars
declare -lrx OSINTSH_ACTUAL_USER="${SUDO_USER:-$USER}"
declare -lurx OSINTSH_SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
declare -lurx OSINTSH_LIB_DIR="$OSINTSH_SCRIPT_DIR/lib"

shopt -s globstar
for __script_path in $OSINTSH_LIB_DIR/**/*.lib.sh; do
    [[ -f $__script_path ]] && source $__script_path
done

# --> END GENERATED CODE <-- #

# ----------------------------------------- #
#              Handle Arguments             #
# ----------------------------------------- #

while [ $# -gt 0 ]; do
  case $1 in
    help | -h | --help)
        _usage
        exit 0
        ;;
    -l | --log)
        SCRIPT_ARGS_LOG_ENABLED=0 ;;
    --log-output)
        if [ -z "$2" ] || [[ "$2" == -* ]]; then
            _print color red "File not specified." >&2
            _usage
            exit 1
        fi
        SCRIPT_ARGS_CUSTOM_LOG_OUTPUT_ENABLED=0

        if [ "$SCRIPT_ARGS_LOG_ENABLED" = 0 ]; then
            SCRIPT_ARGS_CUSTOM_LOG_OUTPUT_LOCATION="$2"
            LOG_FILE="$2"
        fi

        shift 2
        continue
        ;;
    -v | --verbose)
        SCRIPT_ARGS_VERBOSE_ENABLED=0
        VERBOSE=0
        _verbose
        ;;
    --insane-verbose)
        SCRIPT_ARGS_INSANE_VERBOSE_ENABLED=0
        _insane_verbose
        ;;
    -n | --no-install)
        SCRIPT_ARGS_NO_INSTALL_ENABLED=0
        ;;
    --local-install-bin)
        SCRIPT_ARGS_LOCAL_INSTALL_BIN=$2
        ;;
    --install-dir)
        SCRIPT_ARGS_INSTALL_DIR=$2
        INSTALL_DIR=$2
        ;;
    --blackbird-dir)
        SCRIPT_ARGS_BLACKBIRD_INSTALL_DIR=$2
        BLACKBIRD_INSTALL_DIR=$2
        ;;
    init | -i | --init)
        _add_self_to_path
        exit 0
        ;;
    *)
        echo "$(_print color red "Invalid option:") $1" >&2
        usage
        exit 1
        ;;
  esac
  shift
done

# ----------------------------------------- #
#            End Handle Arguments           #
# ----------------------------------------- #

# ----------------------------------------- #
#                   Init                    #
# ----------------------------------------- #

clear

_main_menu

# ----------------------------------------- #
#                  End Init                 #
# ----------------------------------------- #
