# ----------------------------------------- #
#         System Management Library         #
# ----------------------------------------- #

GUM_CHOOSE_STYLE=""

_print() {
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

 _run_as_user() {
    runuser --user $OSINTSH_ACTUAL_USER -- bash -lic "$* > /dev/null" > /dev/null
}
export -f _run_as_user

_command_success() {
    local command_output
    [[ ! -z ${1:-} ]] && command_output=$1
    if [[ $? -ne 0 || $command_output == *"string"* || $command_output == *"strong"* ]]; then
        return 1
    else
        return 0
    fi
}

_command_exists() {
    if command -v "$1" > /dev/null; then
        return 0
    else
        return 1
    fi
}

_package_manager() {
    local TYPE PACKAGE PACKAGE_MANAGER
    [[ ! -z ${1:-} ]] && TYPE=$1
    [[ ! -z ${2:-} ]] && PACKAGE=$2

    check() {
        if _command_exists apt; then
            echo apt
        elif _command_exists yum; then
            echo yum
        elif _command_exists dnf; then
            echo dnf
        elif _command_exists pacman; then
            echo pacman
        elif _command_exists rpm; then
            echo rpm
        elif _command_exists zypper; then
            echo zypper
        elif _command_exists flox; then
            echo flox
        elif _command_exists nix-env; then
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
                if ! apt-get install -yfq "$1" > /dev/null; then
                    apt-get install -ymq "$1" > /dev/null
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