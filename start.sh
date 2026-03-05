#!/usr/bin/env bash

# ----------------------------------------- #
#              Load needed vars             #
# ----------------------------------------- #

export PATH="$PATH"

# ----------------------------------------- #
#            End load needed vars           #
# ----------------------------------------- #

# ----------------------------------------- #
#       Make sure you are using bash        #
# ----------------------------------------- #

if [ -z "${BASH_VERSION:-}" ]; then
    if ! exec /usr/bin/env bash "$0" "$@"; then
        echo "You need to use bash to run this script."
        exit 1
    fi
fi

# ----------------------------------------- #
#      End make sure you are using bash     #
# ----------------------------------------- #

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
readonly OSINTSH_ACTUAL_USER="${SUDO_USER:-$USER}"; export OSINTSH_ACTUAL_USER
readonly OSINTSH_SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ); export OSINTSH_SCRIPT_DIR
readonly OSINTSH_LIB_DIR="$OSINTSH_SCRIPT_DIR/lib"; export OSINTSH_LIB_DIR

shopt -s globstar
for __script_path in $OSINTSH_LIB_DIR/**/*.lib.sh; do
    [[ -f $__script_path ]] && source $__script_path
done

# --> END GENERATED CODE <-- #

# ----------------------------------------- #
#                   Init                    #
# ----------------------------------------- #

clear

_main_menu

# ----------------------------------------- #
#                  End Init                 #
# ----------------------------------------- #
