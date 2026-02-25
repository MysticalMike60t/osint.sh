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

set -ebhmuo pipefail

# ----------------------------------------- #
#             End Bash env init             #
# ----------------------------------------- #

# ----------------------------------------- #
#          Ask for admin privledges         #
# ----------------------------------------- #

if [ "$EUID" != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

# ----------------------------------------- #
#        End Ask for admin privledges       #
# ----------------------------------------- #

# ----------------------------------------- #
#         Entry Variable Definitions        #
# ----------------------------------------- #

# Static strings
readonly TITLE="OSINT.sh"

# Version Definitions
readonly BLACKBIRD_PYTHON_VERSION=3.14.3

# OS / System info vars
ACTUAL_USER="${SUDO_USER:-$USER}"

ERRORS=0
VERBOSE=false
LOG_FILE="./osint.sh.log"
LOCAL_INSTALL_BIN="/home/$ACTUAL_USER/.local/bin"
BLACKBIRD_INSTALL_DIR="/home/$ACTUAL_USER/.local/share/blackbird"
# Initial arg variable values
SCRIPT_ARGS_CUSTOM_LOG_OUTPUT_ENABLED=false
SCRIPT_ARGS_CUSTOM_LOG_OUTPUT_LOCATION=$LOG_FILE
SCRIPT_ARGS_VERBOSE_ENABLED=false
SCRIPT_ARGS_NO_INSTALL_ENABLED=false
SCRIPT_ARGS_BLACKBIRD_INSTALL_DIR=$BLACKBIRD_INSTALL_DIR
SCRIPT_ARGS_LOCAL_INSTALL_BIN=$LOCAL_INSTALL_BIN

export PATH="$LOCAL_INSTALL_BIN:$PATH"

# ----------------------------------------- #
#       End Entry Variable Definitions      #
# ----------------------------------------- #

# ----------------------------------------- #
#         System Management Library         #
# ----------------------------------------- #

GUM_CHOOSE_STYLE=""

run_as_user() {
    runuser --user $ACTUAL_USER -- bash -lic "$*"
}

command_success() {
    local command_output
    [[ ! -z ${1:-} ]] && command_output=$1
    if [[ $? -ne 0 || $command_output == *"string"* || $command_output == *"strong"* ]]; then
        return 1
    else
        return 0
    fi
}

command_exists() {
    if command -v "$1" > /dev/null; then
        return 0
    else
        return 1
    fi
}

package_manager() {
    local TYPE PACKAGE PACKAGE_MANAGER
    [[ ! -z ${1:-} ]] && TYPE=$1
    [[ -n $2 ]] && PACKAGE=$2

    check() {
        if command_exists apt; then
            echo apt
        elif command_exists yum; then
            echo yum
        elif command_exists dnf; then
            echo dnf
        elif command_exists pacman; then
            echo pacman
        elif command_exists rpm; then
            echo rpm
        elif command_exists zypper; then
            echo zypper
        elif command_exists flox; then
            echo flox
        elif command_exists nix-env; then
            echo nix-env
        fi
    }

    PACKAGE_MANAGER=$(check)

    update() {
        case $PACKAGE_MANAGER in
            apt)
                apt-get update -qq > /dev/null
                ;;
        esac
    }
    diag() {
        case $PACKAGE_MANAGER in
            apt)
                apt-get check $1 > /dev/null
                ;;
        esac
    }
    clean() {
        local TYPE
        [[ ! -z ${1:-} ]] && TYPE=$1

        case $TYPE in
            savespace)
                case $PACKAGE_MANAGER in
                    apt)
                        update
                        apt-get autoremove -yfq > /dev/null
                        apt-get clean -yfq > /dev/null
                        ;;
                esac
                ;;
            unused)
                case $PACKAGE_MANAGER in
                    apt)
                        update
                        apt-get autoremove -yfq > /dev/null
                        apt-get autoclean -yfq > /dev/null
                        ;;
                esac
                ;;
        esac
    }
    upgrade() {
        case $PACKAGE_MANAGER in
            apt)
                apt-get upgrade -yfq $1 > /dev/null
                ;;
        esac
    }
    upgrade_all() {
        case $PACKAGE_MANAGER in
            apt)
                update
                apt-get upgrade -yfq > /dev/null
                ;;
        esac
    }
    full_upgrade() {
        case $PACKAGE_MANAGER in
            apt)
                update
                update-all
                apt-get dist-upgrade -yfq > /dev/null
                clean unused
                ;;
        esac
    }
    install() {
        case $PACKAGE_MANAGER in
            apt)
                update
                if ! sudo apt-get install -yfq "$1" > /dev/null; then
                    sudo apt-get install -ymq "$1" > /dev/null
                fi
                ;;
        esac
    }
    remove() {
        case $PACKAGE_MANAGER in
            apt)
                apt-get remove -yfq $1 > /dev/null
                ;;
        esac
    }
    purge() {
        case $PACKAGE_MANAGER in
            apt)
                apt-get remove --purge -yfq $1 > /dev/null
                ;;
        esac
    }

    case $TYPE in
        check)
            echo $PACKAGE_MANAGER ;;
        install)
            install $PACKAGE ;;
        update)
            update ;;
        upgrade)
            upgrade $PACKAGE ;;
        remove)
            remove $PACKAGE ;;
        purge)
            purge $PACKAGE ;;
        clean)
            clean ;;
        upgrade-all)
            upgrade_all ;;
        full-upgrade)
            full_upgrade ;;
    esac
}

# ----------------------------------------- #
#       End System Management Library       #
# ----------------------------------------- #

# ----------------------------------------- #
#              Program Library              #
# ----------------------------------------- #

use_python() {
    local TYPE FILENAME REST
    [[ ! -z ${1:-} ]] && TYPE=$1
    [[ ! -z ${2:-} ]] && FILENAME=$2
    shift 2
    [[ ! -z ${*:-} ]] && REST=$*

    if command_exists pyenv; then
        export PATH="/home/$ACTUAL_USER/.pyenv/bin:$PATH"
        eval "$(run_as_user pyenv init - bash)"
        export PYENV_INSTALLER_SKIP_PROMPTS=1
    fi

    create_env() {
        if command_exists pyenv; then
            run_as_user pyenv install -s 3.14.3

            local PYTHON_BIN="/home/$ACTUAL_USER/.pyenv/versions/3.14.3/bin/python"

            if [[ ! -x "$PYTHON_BIN" ]]; then
                echo "Python version not installed via pyenv"
                return 1
            fi

            "$PYTHON_BIN" -m venv .venv
        else
            if command_exists python3; then
                python3 -m venv .venv
            else
                python -m venv .venv
            fi
        fi
    }
    run_script() {
        local OPTIONS
        [[ ! -z ${1:-} ]] && OPTIONS=$("./$1")
        shift 1
        [[ ! -z ${*:-} ]] && OPTIONS=$("./$1" "$@")

        if command_exists pyenv; then
            run_as_user pyenv exec python $OPTIONS
        else
            if command_exists python3; then
                python3 $OPTIONS
            elif command_exists python; then
                python $OPTIONS
            fi
        fi
    }

    case $TYPE in
        createenv)
            create_env
            ;;
        run)
            create_env
            if [[ -n $REST ]]; then
                run_script $FILENAME $REST
            else
                run_script $FILENAME
            fi
            ;;
    esac
}

run_gum() {
    local TYPE OPTIONS
    [[ ! -z ${1:-} ]] && TYPE=$1
    shift 1
    [[ ! -z ${*:-} ]] && OPTIONS=$*

    confirm() {
        if command_exists gum; then
            if [[ ! -z ${1:-} ]]; then
                gum confirm "$@" && return 0 || return 1
            # else
                gum confirm && return 0 || return 1
            fi
        # else
            # return 1
        fi
    }
    choose() {
        if command_exists gum; then
            if [[ ! -z ${*:-} ]]; then
                local RESTARGS
                RESTARGS=$*
                gum choose $GUM_CHOOSE_STYLE $RESTARGS && return 0 || return 1
            # else
                # return 1
            fi
        # else
            # return 1
        fi
    }

    case $TYPE in
        confirm)
            confirm "${OPTIONS[@]}"
            ;;
        choose)
            choose $OPTIONS
            ;;
    esac
}

install_blackbird() {
    while true; do
        if ! command_exists git; then
            install pkgmgr git
            continue
        fi
        local current_dir
        current_dir=$(pwd)
        rm -rf $BLACKBIRD_INSTALL_DIR
        rm -f $LOCAL_INSTALL_BIN/blackbird
        rm -f /etc/environment.d/99-blackbird.conf
        if $VERBOSE; then
            mkdir -pv "$BLACKBIRD_INSTALL_DIR" "$LOCAL_INSTALL_BIN"
            git -v clone https://github.com/p1ngul1n0/blackbird "$BLACKBIRD_INSTALL_DIR"
        else
            mkdir -p "$BLACKBIRD_INSTALL_DIR" "$LOCAL_INSTALL_BIN"
            git clone https://github.com/p1ngul1n0/blackbird "$BLACKBIRD_INSTALL_DIR"
        fi
        cd $BLACKBIRD_INSTALL_DIR
        use_python createenv
        source "$BLACKBIRD_INSTALL_DIR/.venv/bin/activate" && pip install -r requirements.txt
        printf "PATH=\"%s:\$PATH\"" $BLACKBIRD_INSTALL_DIR:$LOCAL_INSTALL_BIN >> /etc/environment.d/99-blackbird.conf
        printf "#!/usr/bin/env bash\nset -euo pipefail\ncurrent_dir=\$(pwd)\nWRKDIR=\"%s\"\nVENV=\"\$WRKDIR/.venv\"\nSCRIPT=\"\$WRKDIR/blackbird.py\"\nif [[ ! -d \"\$VENV\" ]]; then\necho \"Error: Virtual environment not found at \$VENV\"\nexit 1\nfi\nsource \"\$VENV/bin/activate\"\ncd \"\$WRKDIR\"\npython \"\$SCRIPT\" \"\$@\"\ndeactivate\ncd \$current_dir" $BLACKBIRD_INSTALL_DIR >> $LOCAL_INSTALL_BIN/blackbird
        chown $ACTUAL_USER:$ACTUAL_USER $LOCAL_INSTALL_BIN/blackbird
        chmod +x $LOCAL_INSTALL_BIN/blackbird
        cd $current_dir

        return 0
    done
}

start_blackbird() {
    local TYPE INSTALL_DIR
    [[ ! -z ${1:-} ]] && TYPE=$1
    INSTALL_DIR=$BLACKBIRD_INSTALL_DIR
    type() {
        case "$TYPE" in
            "username")
                local value
                value=$(gum input --placeholder "What username?")
                echo "--username $value" ;;
            "email")
                local value
                value=$(gum input --placeholder "What email?")
                echo "--email $value" ;;
            *)
                echo "" ;;
        esac
    }
    output() {
        if run_gum confirm "Specify Output?"; then
            local choice
            choice=$(gum choose $GUM_CHOOSE_STYLE "csv" "pdf" "json" "cancel")
            case "$choice" in
                "csv") echo "--csv" ;;
                "pdf") echo "--pdf" ;;
                "json") echo "--json" ;;
                "cancel") output ;;
            esac
            echo "Outputs are stored in: $INSTALL_DIR/results" 1>&3
        fi
    }
    verbose() {
        if run_gum confirm "Run verbose?"; then
            echo "--verbose"
        fi
    }
    proxy() {
        if run_gum confirm "Use proxy?"; then
            local value
            value=$(gum input --placeholder "Proxy URL?")
            echo "--proxy $value"
        fi
    }
    nsfw() {
        if run_gum confirm "Remove NSFW results?"; then
            echo "--no-nsfw"
        fi
    }
    extra_params() {
        if run_gum confirm "Add extra parameters?"; then
            gum input --placeholder "Enter extra parameters"
        fi
    }

    if [[ ! -d $INSTALL_DIR ]] || [[ ! -f $LOCAL_INSTALL_BIN/blackbird ]] || [[ ! -f /etc/environment.d/99-blackbird.conf ]]; then
        if ! install_blackbird; then
            printf "Could not install blackbird..."
        fi
    fi

    local TYPE_ARG OUTPUT_ARG VERBOSE_ARG PROXY_ARG NSFW_ARG EXTRA_ARG
    TYPE_ARG=$(type)
    OUTPUT_ARG=$(output)
    VERBOSE_ARG=$(verbose)
    PROXY_ARG=$(proxy)
    NSFW_ARG=$(nsfw)
    EXTRA_ARG=$(extra_params)

    clear
    blackbird $TYPE_ARG $OUTPUT_ARG $VERBOSE_ARG $PROXY_ARG $NSFW_ARG $EXTRA_ARG
    exit
}

# ----------------------------------------- #
#            End Program Library            #
# ----------------------------------------- #

# ----------------------------------------- #
#               Custom Library              #
# ----------------------------------------- #

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo " help, -h, --help      Display this help message"
    echo " -v, --verbose         Enable verbose mode"
    echo " -n, --no-install      Don't install non-installed packages and/or programs"
    echo " --log-output          Specify location of log output file"
}

has_argument() {
    [[ ("$1" == *=* && -n ${1#*=}) || ( ! -z "$2" && "$2" != -*)  ]];
}

extract_argument() {
  echo "${2:-${1#*=}}"
}

verbose() {
    set -x
}

insane_verbose() {
    var_details() {
        ls -lh $1
    }
    
    verbose
    var_details $ERRORS
}

install() {
    local NAME TYPE REST
    NAME=$1
    TYPE=$2
    shift 2
    REST=$*

    case $TYPE in
        pkgmgr)
            if [[ -n $REST ]]; then
                package_manager $NAME $REST
            else
                package_manager $NAME
            fi
            ;;
        custom)
            case $NAME in
                blackbird)
                    install_blackbird
                    ;;
            esac
            ;;
    esac
}

# ----------------------------------------- #
#             End Custom Library            #
# ----------------------------------------- #

# ----------------------------------------- #
#              Handle Arguments             #
# ----------------------------------------- #

while [ $# -gt 0 ]; do
  case $1 in
    help | -h | --help)
        usage
        ;;
    -l | --log)
        SCRIPT_ARGS_LOG_ENABLED=true ;;
    --log-output)
        if [ -z "$2" ] || [[ "$2" == -* ]]; then
            echo "File not specified." >&2
            usage
            exit 1
        fi
        SCRIPT_ARGS_CUSTOM_LOG_OUTPUT_ENABLED=true

        if [ "$SCRIPT_ARGS_LOG_ENABLED" = true ]; then
            SCRIPT_ARGS_CUSTOM_LOG_OUTPUT_LOCATION="$2"
            LOG_FILE="$2"
        fi

        shift 2
        continue
        ;;
    -v | --verbose)
        SCRIPT_ARGS_VERBOSE_ENABLED=true
        VERBOSE=true
        verbose
        ;;
    --insane-verbose)
        SCRIPT_ARGS_INSANE_VERBOSE_ENABLED=true
        insane_verbose
        ;;
    -n | --no-install)
        SCRIPT_ARGS_NO_INSTALL_ENABLED=true
        ;;
    --local-install-bin)
        SCRIPT_ARGS_LOCAL_INSTALL_BIN=$2
        ;;
    --blackbird-dir)
        SCRIPT_ARGS_BLACKBIRD_INSTALL_DIR=$2
        BLACKBIRD_INSTALL_DIR=$2
        ;;
    *)
        echo "Invalid option: $1" >&2
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
#                   Menus                   #
# ----------------------------------------- #

username_menu() {
    while true; do
        if command_exists gum; then
            local choice options
            options=("Blackbird" "Back")
            choice=$(gum choose $GUM_CHOOSE_STYLE "${options[@]}")
            clear
            case $choice in
                "Blackbird") start_blackbird "username" ;;
                "Back") clear && main_menu ;;
            esac
        fi
    done
}

email_menu() {
    while true; do
        if command_exists gum; then
            local choice options
            options=("Blackbird" "Back")
            choice=$(run_gum choose $GUM_CHOOSE_STYLE "${options[@]}")
            clear
            case $choice in
                "Blackbird") start_blackbird "email" ;;
                "Back") clear && main_menu ;;
            esac
        fi
    done
}

main_menu() {
    while true; do
        if command_exists gum; then
            local choice options
            local options=("Username" "Email" "Exit")
            choice=$(run_gum choose $GUM_CHOOSE_STYLE "${options[@]}")
            clear
            case $choice in
                "Username") username_menu ;;
                "Email") email_menu ;;
                "Exit") clear && exit ;;
            esac
        else
            install_gum() {
                case $PACKAGE_MANAGER in
                    apt)
                        mkdir -p /etc/apt/keyrings
                        curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg
                        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | tee /etc/apt/sources.list.d/charm.list
                        install pkgmgr gum
                        ;;
                    yum)
                        install pkgmgr gum
                        ;;
                    zypper)
                        install pkgmgr gum
                        ;;
                    dnf)
                        install pkgmgr gum
                        ;;
                    nix-env)
                        install pkgmgr nixpkgs.gum
                        ;;
                    pacman)
                        install pkgmgr gum
                        ;;
                    flox)
                        install pkgmgr gum
                        ;;
                    *)
                        if command_exists brew; then
                            brew install gum
                        elif command_exists go; then
                            go install github.com/charmbracelet/gum@latest
                        else
                            echo "error can't install gum :("
                            echo "Install from here: https://github.com/charmbracelet/gum"
                            exit 1;
                        fi
                        ;;
                esac
            }
            echo "Gum is not installed. You need it to use this program."
            echo "Do you want to install it?"
            select strictreply in "Yes" "No"; do
                relaxedreply=${strictreply:-$REPLY}
                case $relaxedreply in
                    Yes | yes | y ) install_gum ; break ;;
                    No  | no  | n ) break ;;
                esac
            done
        fi
    done
}

# ----------------------------------------- #
#                 End Menus                 #
# ----------------------------------------- #

# ----------------------------------------- #
#                   Init                    #
# ----------------------------------------- #

clear

main_menu

return $ERRORS

# ----------------------------------------- #
#                  End Init                 #
# ----------------------------------------- #
