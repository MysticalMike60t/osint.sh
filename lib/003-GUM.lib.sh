# ----------------------------------------- #
#                    Gum                    #
# ----------------------------------------- #

_gum() {
    local TYPE
    TYPE="$1"
    shift

    local OPTIONS=("$@")

    export GUM_INPUT_CURSOR_FOREGROUND="#FF0"
    export GUM_INPUT_PROMPT_FOREGROUND="#0FF"
    export GUM_INPUT_PROMPT="* "
    export GUM_INPUT_WIDTH=80

    confirm() {
        if _command_exists gum; then
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
        if _command_exists gum; then
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
        if _command_exists gum; then
            local SPINNER_TITLE="$1"
            shift

            gum spin --spinner points --title "$SPINNER_TITLE" -- "$@"
        else
            "$@"
        fi
    }
    internet_spin() {
        if _command_exists gum; then
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

# ----------------------------------------- #
#                  End Gum                  #
# ----------------------------------------- #