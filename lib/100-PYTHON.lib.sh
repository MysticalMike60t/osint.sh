# ----------------------------------------- #
#                  Python                   #
# ----------------------------------------- #

_python() {
    local TYPE FILENAME REST
    [[ ! -z ${1:-} ]] && TYPE=$1
    [[ ! -z ${2:-} ]] && FILENAME=$2
    shift 2
    [[ ! -z ${*:-} ]] && REST=$*

    if _command_exists pyenv; then
        declare -lux PATH="/home/$OSINTSH_ACTUAL_USER/.pyenv/bin:$PATH"
        eval "$(_run_as_user pyenv init - bash 2>/dev/null)"
        declare -irx PYENV_INSTALLER_SKIP_PROMPTS=1
    fi

    create_env() {
        if _command_exists pyenv; then
            _gum spin "Installing Python 3.14.3..." bash -c "_run_as_user 'pyenv install -s 3.14.3 2>/dev/null'"

            declare -lux PYTHON_BIN="/home/$OSINTSH_ACTUAL_USER/.pyenv/versions/3.14.3/bin/python"

            if [[ ! -x "$PYTHON_BIN" ]]; then
                echo "Python version not installed via pyenv"
                return 1
            fi

            "$PYTHON_BIN" -m venv .venv
        else
            if _command_exists python3; then
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

        if _command_exists pyenv; then
            _run_as_user pyenv exec python $OPTIONS 2>/dev/null
        else
            if _command_exists python3; then
                python3 $OPTIONS
            elif _command_exists python; then
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

# ----------------------------------------- #
#                 End Python                #
# ----------------------------------------- #