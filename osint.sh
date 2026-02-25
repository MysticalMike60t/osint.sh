#!/bin/bash

if [ ! $SHELL = "bash" ]; then
    echo "You need to use bash to run this script. You are on $SHELL."
    return 1
fi

# ----------------------------------------- #
#               Bash env init               #
# ----------------------------------------- #

set -ebhm

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

readonly TITLE="OSINT.sh"
ERRORS=0
LOG_FILE="./osint.sh.log"
# Initial arg variable values
SCRIPT_ARGS_CUSTOM_LOG_OUTPUT_ENABLED=false
SCRIPT_ARGS_CUSTOM_LOG_OUTPUT_LOCATION=$LOG_FILE
SCRIPT_ARGS_VERBOSE_ENABLED=false
SCRIPT_ARGS_NO_INSTALL_ENABLED=false

# ----------------------------------------- #
#       End Entry Variable Definitions      #
# ----------------------------------------- #

# ----------------------------------------- #
#         System Management Library         #
# ----------------------------------------- #

GUM_CHOOSE_STYLE=""

command_success() {
    local command_output
    command_output=$1
    if [[ $? -ne 0 || $command_output == *"string"* || $command_output == *"strong"* ]]; then
        return 1
    else
        return 0
    fi
}

command_exists() {
    if command -v $1 > /dev/null; then
        return 0
    else
        return 1
    fi
}

package_manager() {
    local TYPE PACKAGE PACKAGE_MANAGER
    TYPE=$1
    PACKAGE=$2

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
        TYPE=$1

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
    local TYPE
    TYPE=$1

    case $TYPE in
        createenv)
            if command_exists pyenv; then
                pyenv local 3
                pyenv exec -m python venv .venv 
            else
                if command_exists python3; then
                    python3 -m venv .venv
                elif command_exists python; then
                    python -m venv .venv
                fi
            fi
            ;;
    esac
}

start_blackbird() {
    local TYPE INSTALL_DIR
    TYPE=$1
    INSTALL_DIR="$HOME/.local/share/blackbird"

    confirm() {
        gum confirm && return 0 || return 1
    }
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
        if gum confirm "Specify Output?"; then
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
        if gum confirm "Run verbose?"; then
            echo "--verbose"
        fi
    }
    proxy() {
        if gum confirm "Use proxy?"; then
            local value
            value=$(gum input --placeholder "Proxy URL?")
            echo "--proxy $value"
        fi
    }
    nsfw() {
        if gum confirm "Remove NSFW results?"; then
            echo "--no-nsfw"
        fi
    }
    extra_params() {
        if gum confirm "Add extra parameters?"; then
            gum input --placeholder "Enter extra parameters"
        fi
    }

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
    var_details 
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
            LOG_FILE="$SCRIPT_ARGS_CUSTOM_LOG_OUTPUT_LOCATION"
        fi

        shift 2
        continue
        ;;
    -v | --verbose)
        SCRIPT_ARGS_VERBOSE_ENABLED=true
        verbose
        ;;
    --insane-verbose)
        SCRIPT_ARGS_INSANE_VERBOSE_ENABLED=true
        insane_verbose
        ;;
    -n | --no-install)
        SCRIPT_ARGS_NO_INSTALL_ENABLED=true
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
        if command -v gum > /dev/null; then
            local choice
            choice=$(gum choose $GUM_CHOOSE_STYLE "Blackbird" "Back")
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
        if command -v gum > /dev/null; then
            local choice
            choice=$(gum choose $GUM_CHOOSE_STYLE "Blackbird" "Back")
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
        if command -v gum > /dev/null; then
            local choice
            choice=$(gum choose $GUM_CHOOSE_STYLE "Username" "Email" "Exit")
            clear
            case $choice in
                "Username") username_menu ;;
                "Email") email_menu ;;
                "Exit") clear && exit ;;
            esac
        else
            check() {
                case $PACKAGE_MANAGER in
                    apt)
                        mkdir -p /etc/apt/keyrings
                        curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg
                        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | tee /etc/apt/sources.list.d/charm.list
                        package_manager update
                        package_manager install gum
                        ;;
                    yum)
                        yum install gum
                        ;;
                    zypper)
                        zypper refresh
                        zypper install gum
                        ;;
                    dnf)
                        dnf install gum
                        ;;
                    nix-env)
                        nix-env -iA nixpkgs.gum
                        ;;
                    pacman)
                        pacman -S gum
                        ;;
                    flox)
                        flox install gum
                        ;;
                    *)
                        if command -v brew > /dev/null; then
                            brew install gum
                        elif command -v go > /dev/null; then
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
            select yn in "Yes" "No"; do
                case $yn in
                    Yes ) check ; break ;;
                    No ) exit ;;
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

package_manager install git

main_menu

return $ERRORS

# ----------------------------------------- #
#                  End Init                 #
# ----------------------------------------- #
