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

set -uo pipefail
set +m

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

# ----------------------------------------- #
#         Entry Variable Definitions        #
# ----------------------------------------- #

# Basic Fast shit
readonly ANSI_BLACK='\033[0;30m'
readonly ANSI_RED='\033[0;31m'
readonly ANSI_GREEN='\033[0;32m'
readonly ANSI_ORANGE='\033[0;33m'
readonly ANSI_BLUE='\033[0;34m'
readonly ANSI_PURPLE='\033[0;35m'
readonly ANSI_CYAN='\033[0;36m'
readonly ANSI_LIGHT_GRAY='\033[0;37m'
readonly ANSI_DARK_GRAY='\033[1;30m'
readonly ANSI_LIGHT_RED='\033[1;31m'
readonly ANSI_LIGHT_GREEN='\033[1;32m'
readonly ANSI_YELLOW='\033[1;33m'
readonly ANSI_LIGHT_BLUE='\033[1;34m'
readonly ANSI_LIGHT_PURPLE='\033[1;35m'
readonly ANSI_LIGHT_CYAN='\033[1;36m'
readonly ANSI_WHITE='\033[1;37m'
readonly ANSI_NC='\033[0m' 

# Static strings
readonly TITLE="OSINT.sh"

# OS / System info vars
ACTUAL_USER="${SUDO_USER:-$USER}"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

ERRORS=0
VERBOSE=1
LOG_FILE="./osint.sh.log"
INSTALL_DIR="/home/$ACTUAL_USER/.local/share/osint.sh"
LOCAL_INSTALL_BIN="/home/$ACTUAL_USER/.local/bin"
BLACKBIRD_INSTALL_DIR="/home/$ACTUAL_USER/.local/share/blackbird"
# Initial arg variable values
SCRIPT_ARGS_INSTALL_DIR=$INSTALL_DIR
SCRIPT_ARGS_CUSTOM_LOG_OUTPUT_ENABLED=1
SCRIPT_ARGS_CUSTOM_LOG_OUTPUT_LOCATION=$LOG_FILE
SCRIPT_ARGS_VERBOSE_ENABLED=1
SCRIPT_ARGS_NO_INSTALL_ENABLED=1
SCRIPT_ARGS_BLACKBIRD_INSTALL_DIR=$BLACKBIRD_INSTALL_DIR
SCRIPT_ARGS_LOCAL_INSTALL_BIN=$LOCAL_INSTALL_BIN

export PATH="$LOCAL_INSTALL_BIN:$PATH"

# ----------------------------------------- #
#       End Entry Variable Definitions      #
# ----------------------------------------- #

# ----------------------------------------- #
#          Bash Management Library          #
# ----------------------------------------- #

cleanup() {
    clear

    echo -e "${ANSI_PURPLE}Bye Bye :3${ANSI_NC}"
    kill -INT $$ 2>/dev/null
} >&2

# ----------------------------------------- #
#        End Bash Management Library        #
# ----------------------------------------- #

# ----------------------------------------- #
#         System Management Library         #
# ----------------------------------------- #

GUM_CHOOSE_STYLE=""

print() {
    local TYPE OPTION1 PRESET
    [[ ! -z ${1:-} ]] && TYPE=$1
    [[ ! -z ${2:-} ]] && OPTION1=$2
    shift 2

    print() {
        local START PRESET
        START=$1
        shift 1
        [[ ! -z ${2:-} ]] && PRESET=$2 && shift 1
        case $PRESET in
            error)
                error 
                ;;
            *)
                echo -e "${START}$*${ANSI_NC}"
                ;;
        esac
    }

    error() {
        local TYPE LAYER
        TYPE=$1
        shift 1
        [[ ! -z ${2:-} ]] && LAYER=$2
        [[ ! -z ${2:-} ]] && shift 2
        case $TYPE in
            simple)
                case $LAYER in
                    1)
                        echo -e "${ANSI_LIGHT_RED}-[!]  $*  [!]-${ANSI_NC}"
                        ;;
                    2)
                        echo -e "${ANSI_LIGHT_RED}--[!]  $*  [!]--${ANSI_NC}"
                        ;;
                    3)
                        echo -e "${ANSI_LIGHT_RED}---[!]  $*  [!]---${ANSI_NC}"
                        ;;
                    4)
                        echo -e "${ANSI_LIGHT_RED}----[!]  $*  [!]----${ANSI_NC}"
                        ;;
                    5)
                        echo -e "${ANSI_LIGHT_RED}-----[!]  $*  [!]-----${ANSI_NC}"
                        ;;
                    *)
                        echo -e "${ANSI_LIGHT_RED}[!]  $*  [!]${ANSI_NC}"
                        ;;
                esac
                ;;
        esac
        }

    case $TYPE in
        color)
            case $OPTION1 in
                red)
                    print $ANSI_RED "$*"
                    ;;
                orange)
                    print $ANSI_ORANGE "$*"
                    ;;
                yellow)
                    print $ANSI_YELLOW "$*"
                    ;;
                green)
                    print $ANSI_GREEN "$*"
                    ;;
                cyan)
                    print $ANSI_CYAN "$*"
                    ;;
                blue)
                    print $ANSI_BLUE "$*"
                    ;;
                purple)
                    print $ANSI_PURPLE "$*"
                    ;;
                white)
                    print $ANSI_WHITE "$*"
                    ;;
                black)
                    print $ANSI_BLACK "$*"
                    ;;
                light-red)
                    print $ANSI_LIGHT_RED "$*"
                    ;;
                light-green)
                    print $ANSI_LIGHT_GREEN "$*"
                    ;;
                light-cyan)
                    print $ANSI_LIGHT_CYAN "$*"
                    ;;
                light-blue)
                    print $ANSI_LIGHT_BLUE "$*"
                    ;;
                light-purple)
                    print $ANSI_LIGHT_PURPLE "$*"
                    ;;
                light-gray)
                    print $ANSI_LIGHT_GRAY "$*"
                    ;;
                dark-gray)
                    print $ANSI_DARK_GRAY "$*"
                    ;;
            esac
            ;;
            error)
                error simple "$OPTION1" "$@"
                ;;
    esac
}

run_as_user() {
    runuser --user $ACTUAL_USER -- bash -lic "$* > /dev/null" > /dev/null
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
    [[ ! -z ${2:-} ]] && PACKAGE=$2

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

run_gum() {
    local TYPE
    TYPE="$1"
    shift

    local OPTIONS=("$@")

    export GUM_INPUT_CURSOR_FOREGROUND="#FF0"
    export GUM_INPUT_PROMPT_FOREGROUND="#0FF"
    export GUM_INPUT_PROMPT="* "
    export GUM_INPUT_WIDTH=80

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
                RESTARGS="$@"
                gum choose $GUM_CHOOSE_STYLE $RESTARGS && return 0 || return 1
            # else
                # return 1
            fi
        # else
            # return 1
        fi
    }
    spin() {
        if command_exists gum; then
            local SPINNER_TITLE="$1"
            shift

            gum spin --spinner points --title "$SPINNER_TITLE" -- "$@"
        else
            "$@"
        fi
    }
    internet_spin() {
        if command_exists gum; then
            local SPINNER_TITLE="$1"
            shift

            gum spin --spinner globe --title "$SPINNER_TITLE" -- "$@"
        else
            "$@"
        fi
    }

    case $TYPE in
        confirm)
            confirm "${OPTIONS[@]}"
            ;;
        choose)
            choose "${OPTIONS[@]}"
            ;;
        spin)
            spin "${OPTIONS[@]}"
            ;;
    esac
}

use_python() {
    local TYPE FILENAME REST
    [[ ! -z ${1:-} ]] && TYPE=$1
    [[ ! -z ${2:-} ]] && FILENAME=$2
    shift 2
    [[ ! -z ${*:-} ]] && REST=$*

    if command_exists pyenv; then
        export PATH="/home/$ACTUAL_USER/.pyenv/bin:$PATH"
        eval "$(run_as_user pyenv init - bash 2>/dev/null)"
        export PYENV_INSTALLER_SKIP_PROMPTS=1
    fi

    create_env() {
        if command_exists pyenv; then
            run_as_user pyenv install -s 3.14.3 2>/dev/null

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
            run_as_user pyenv exec python $OPTIONS 2>/dev/null
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

install_blackbird() {
    while true; do
        clear
        if ! command_exists git; then
            local temp_command=$(install pkgmgr git)
            run_gum spin "Installing git via $PACKAGE_MANAGER" "$temp_command"
            unset temp_command
            continue
        fi
        local current_dir
        current_dir=$(pwd)
        rm -rf $BLACKBIRD_INSTALL_DIR > /dev/null
        rm -f $LOCAL_INSTALL_BIN/blackbird > /dev/null
        rm -f /etc/environment.d/99-blackbird.conf > /dev/null
        if $VERBOSE; then
            mkdir -pv "$BLACKBIRD_INSTALL_DIR" "$LOCAL_INSTALL_BIN" > /dev/null
            run_gum spin "Cloning Blackbird repo..." git -v clone https://github.com/p1ngul1n0/blackbird "$BLACKBIRD_INSTALL_DIR"
        else
            mkdir -p "$BLACKBIRD_INSTALL_DIR" "$LOCAL_INSTALL_BIN" > /dev/null
            run_gum spin "Cloning Blackbird repo..." git clone https://github.com/p1ngul1n0/blackbird "$BLACKBIRD_INSTALL_DIR"
        fi
        cd $BLACKBIRD_INSTALL_DIR
        use_python createenv
        unset temp_command
        run_gum spin "Installing Python requirements..." bash -c "source '$BLACKBIRD_INSTALL_DIR/.venv/bin/activate' && pip install -r requirements.txt"
        run_gum spin "Adding files to PATH..." printf "PATH=\"%s:\$PATH\"" $BLACKBIRD_INSTALL_DIR:$LOCAL_INSTALL_BIN >> /etc/environment.d/99-blackbird.conf
        run_gum spin "Installing to local bin..." printf "#!/usr/bin/env bash\nset -euo pipefail\ncurrent_dir=\$(pwd)\nWRKDIR=\"%s\"\nVENV=\"\$WRKDIR/.venv\"\nSCRIPT=\"\$WRKDIR/blackbird.py\"\nif [[ ! -d \"\$VENV\" ]]; then\necho \"Error: Virtual environment not found at \$VENV\"\nexit 1\nfi\nsource \"\$VENV/bin/activate\"\ncd \"\$WRKDIR\"\npython \"\$SCRIPT\" \"\$@\"\ndeactivate\ncd \$current_dir" $BLACKBIRD_INSTALL_DIR >> $LOCAL_INSTALL_BIN/blackbird
        run_gum spin "Setting user permissions..." bash -c "chown $ACTUAL_USER:$ACTUAL_USER $LOCAL_INSTALL_BIN/blackbird && chmod +x $LOCAL_INSTALL_BIN/blackbird"
        cd $current_dir

        break
    done
    return 0
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
                if [[ -z $value ]]; then
                    cleanup
                fi
                echo "--username $value" ;;
            "email")
                local value
                value=$(gum input --placeholder "What email?")
                if [[ -z $value ]]; then
                    cleanup
                fi
                echo "--email $value" ;;
            *)
                echo "" ;;
        esac
    }
    output() {
        run_gum confirm "Specify Output?"
        case $? in
            0) ;;
            1) return 0 ;;
            130) return 130 ;;
        esac

        local choice
        choice=$(gum choose $GUM_CHOOSE_STYLE "csv" "pdf" "json" "cancel") || return 130

        case "$choice" in
            "csv") echo "--csv" ;;
            "pdf") echo "--pdf" ;;
            "json") echo "--json" ;;
            "cancel") output ;;
        esac
    }
    verbose() {
        run_gum confirm "Run verbose?"
        case $? in
            0) ;;
            1) return 0 ;;
            130) return 130 ;;
        esac
        echo "--verbose"
    }
    proxy() {
        run_gum confirm "Use proxy?"
        case $? in
            0) ;;
            1) return 0 ;;
            130) return 130 ;;
        esac
        local value
        value=$(gum input --placeholder "Proxy URL?") || return 130
        echo "--proxy $value"
    }
    nsfw() {
        run_gum confirm "Remove NSFW results?"
        case $? in
            0) ;;
            1) return 0 ;;
            130) return 130 ;;
        esac
        echo "--no-nsfw"
    }
    extra_params() {
        run_gum confirm "Add extra parameters?"
        case $? in
            0) ;;
            1) return 0 ;;
            130) return 130 ;;
        esac
        gum input --placeholder "Enter extra parameters" || return 130
    }

    if [[ ! -d $INSTALL_DIR ]] || [[ ! -f $LOCAL_INSTALL_BIN/blackbird ]] || [[ ! -f /etc/environment.d/99-blackbird.conf ]]; then
        if ! install_blackbird; then
            printf "Could not install blackbird..."
        fi
    fi

    local TYPE_ARG OUTPUT_ARG VERBOSE_ARG PROXY_ARG NSFW_ARG EXTRA_ARG
    TYPE_ARG=$(type) || cleanup
    OUTPUT_ARG=$(output) || cleanup
    VERBOSE_ARG=$(verbose) || cleanup
    PROXY_ARG=$(proxy) || cleanup
    NSFW_ARG=$(nsfw) || cleanup
    EXTRA_ARG=$(extra_params) || cleanup

    echo "Outputs are stored in: $INSTALL_DIR/results"
    exec blackbird $TYPE_ARG $OUTPUT_ARG $VERBOSE_ARG $PROXY_ARG $NSFW_ARG $EXTRA_ARG
    exit 0
}

# ----------------------------------------- #
#            End Program Library            #
# ----------------------------------------- #

# ----------------------------------------- #
#               Custom Library              #
# ----------------------------------------- #

usage() {
    local DISPLAY_NAME
    DISPLAY_NAME=$(print color light-purple ${0#$SCRIPT_DIR/})

    echo -e "Usage: $DISPLAY_NAME $(print color yellow "[")OPTIONS$(print color yellow "]")"
    echo -e "Options:"
    echo -e " $(print color light-cyan "help"), $(print color light-cyan "-h"), $(print color light-cyan "--help")      Display this help message"
    echo -e " $(print color light-cyan "-v"), $(print color light-cyan "--verbose")         Enable verbose mode"
    echo -e " $(print color light-cyan "init"), $(print color light-cyan "-i"), $(print color light-cyan "--init")      Initialize $(print color light-purple "$TITLE") by adding it to $(print color light-blue "PATH"), and installing"
    echo -e " $(print color light-cyan "--insane-verbose")      Verbose on everything possible "
    echo -e " $(print color light-cyan "-n"), $(print color light-cyan "--no-install")      Don't install non-installed packages and/or programs"
    echo -e " $(print color light-cyan "-l"), $(print color light-cyan "--log")             Enable logs"
    echo -e " $(print color light-cyan "--log-output")          Specify location of log output file"
    echo -e " $(print color light-cyan "--blackbird-dir")       Specify directory of $(print color light-green "Blackbird") installation"
    echo -e " $(print color light-cyan "--local-install-bin")   Specify where you want the bin files to be placed"
    echo -e " $(print color light-cyan "--install-dir")         Specify installation directory for $DISPLAY_NAME"
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

add_self_to_path() {
    mkdir -p "$INSTALL_DIR"
    cp "$SCRIPT_DIR/osint.sh" "$INSTALL_DIR/osint"
    chown $ACTUAL_USER:$ACTUAL_USER "$INSTALL_DIR/osint"
    chmod +x "$INSTALL_DIR/osint"
    # FIXME: printf "PATH=\"%s:\$PATH\"" $INSTALL_DIR:$LOCAL_INSTALL_BIN >> /etc/environment.d/99-osint.sh.conf
    printf "export PATH=\"%s:\$PATH\"" $INSTALL_DIR:$LOCAL_INSTALL_BIN >> "/home/$ACTUAL_USER/.bashrc"
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
        exit 0
        ;;
    -l | --log)
        SCRIPT_ARGS_LOG_ENABLED=0 ;;
    --log-output)
        if [ -z "$2" ] || [[ "$2" == -* ]]; then
            print color red "File not specified." >&2
            usage
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
        verbose
        ;;
    --insane-verbose)
        SCRIPT_ARGS_INSANE_VERBOSE_ENABLED=0
        insane_verbose
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
        add_self_to_path
        exit 0
        ;;
    *)
        echo "$(print color red "Invalid option:") $1" >&2
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
            choice=$(run_gum choose $GUM_CHOOSE_STYLE "${options[@]}") || cleanup
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
            choice=$(run_gum choose $GUM_CHOOSE_STYLE "${options[@]}") || cleanup
            clear
            case $choice in
                "Blackbird") start_blackbird "email" ;;
                "Back") clear && main_menu ;;
            esac
        fi
    done
}

main_menu() {
    local PACKAGE_MANAGER
    PACKAGE_MANAGER=$(package_manager check)
    while true; do
        if command_exists gum; then
            local choice options
            local options=("Username" "Email" "Exit")
            choice=$(run_gum choose $GUM_CHOOSE_STYLE "${options[@]}") || cleanup
            clear
            case $choice in
                "Username") username_menu ;;
                "Email") email_menu ;;
                "Exit") clear && exit ;;
            esac
        else
            install_gum() {
                $VERBOSE && echo "Installing gum"
                case $PACKAGE_MANAGER in
                    apt)
                        $VERBOSE && echo "-> Using apt..."
                        mkdir -p /etc/apt/keyrings
                        curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg
                        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | tee /etc/apt/sources.list.d/charm.list
                        install pkgmgr gum
                        ;;
                    yum)
                        $VERBOSE && echo "-> Using yum"
                        install pkgmgr gum
                        ;;
                    zypper)
                        $VERBOSE && echo "-> Using zypper"
                        install pkgmgr gum
                        ;;
                    dnf)
                        $VERBOSE && echo "-> Using dnf"
                        install pkgmgr gum
                        ;;
                    nix-env)
                        $VERBOSE && echo "-> Using nix-env"
                        install pkgmgr nixpkgs.gum
                        ;;
                    pacman)
                        $VERBOSE && echo "-> Using pacman"
                        install pkgmgr gum
                        ;;
                    flox)
                        $VERBOSE && echo "-> Using flox"
                        install pkgmgr gum
                        ;;
                    *)
                        $VERBOSE && print color light-blue "-i]  Failed to use basic package managers, trying other ones...  [i-"
                        if command_exists brew; then
                            $VERBOSE && echo "-> Using brew"
                            brew install gum
                        elif command_exists go; then
                            $VERBOSE && echo "-> Using go"
                            go install github.com/charmbracelet/gum@latest
                        else
                            $VERBOSE && print error simple 1 "Failed to install gum."
                            print error simple 0 "error can't install gum :("
                            echo "Install from here: https://github.com/charmbracelet/gum"
                            $VERBOSE && print error simple 0 "Exiting with error code 1..."
                            exit 1;
                        fi
                        ;;
                esac
            }
            echo "Gum is not installed. You need it to use this program."
            read -p "Do you want to install it? Type y/n?" yesorno
            case "$yesorno" in
                    y* | Y*)  install_gum ;;
                    n* | N*)  echo "You need to install gum."; exit 1 ;;
            esac
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

# ----------------------------------------- #
#                  End Init                 #
# ----------------------------------------- #
