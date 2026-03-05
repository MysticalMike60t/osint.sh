# ----------------------------------------- #
#                 Blackbird                 #
# ----------------------------------------- #

_install_blackbird() {
    while true; do
        clear
        if ! _command_exists git; then
            local temp_command=$(_install pkgmgr git)
            _gum spin "Installing git via $PACKAGE_MANAGER" "$temp_command"
            unset temp_command
            continue
        fi
        local current_dir
        current_dir=$(pwd)
        rm -rf $BLACKBIRD_INSTALL_DIR > /dev/null
        rm -f $LOCAL_INSTALL_BIN/blackbird > /dev/null
        rm -f /etc/environment.d/99-blackbird.conf > /dev/null
        if [[ $VERBOSE -eq 0 ]]; then
            mkdir -pv "$BLACKBIRD_INSTALL_DIR" "$LOCAL_INSTALL_BIN" > /dev/null
            _gum spin "Cloning Blackbird repo..." git -v clone https://github.com/p1ngul1n0/blackbird "$BLACKBIRD_INSTALL_DIR"
        else
            mkdir -p "$BLACKBIRD_INSTALL_DIR" "$LOCAL_INSTALL_BIN" > /dev/null
            _gum spin "Cloning Blackbird repo..." git clone https://github.com/p1ngul1n0/blackbird "$BLACKBIRD_INSTALL_DIR"
        fi
        cd $BLACKBIRD_INSTALL_DIR
        _python createenv
        unset temp_command
        _gum spin "Installing Python requirements..." bash -c "source '$BLACKBIRD_INSTALL_DIR/.venv/bin/activate' && pip install -r requirements.txt"
        _gum spin "Adding files to PATH..." bash -c "mkdir -p /etc/environment.d && printf \"PATH=\"%s:\$PATH\"\" $BLACKBIRD_INSTALL_DIR:$LOCAL_INSTALL_BIN >> /etc/environment.d/99-blackbird.conf"
        _gum spin "Installing to local bin..." printf "#!/usr/bin/env bash\nset -euo pipefail\ncurrent_dir=\$(pwd)\nWRKDIR=\"%s\"\nVENV=\"\$WRKDIR/.venv\"\nSCRIPT=\"\$WRKDIR/blackbird.py\"\nif [[ ! -d \"\$VENV\" ]]; then\necho \"Error: Virtual environment not found at \$VENV\"\nexit 1\nfi\nsource \"\$VENV/bin/activate\"\ncd \"\$WRKDIR\"\npython \"\$SCRIPT\" \"\$@\"\ndeactivate\ncd \$current_dir" $BLACKBIRD_INSTALL_DIR >> $LOCAL_INSTALL_BIN/blackbird
        _gum spin "Setting user permissions..." bash -c "chown $OSINTSH_ACTUAL_USER:$OSINTSH_ACTUAL_USER $LOCAL_INSTALL_BIN/blackbird && chmod +x $LOCAL_INSTALL_BIN/blackbird"
        cd $current_dir

        break
    done
    return 0
}

_start_blackbird() {
    local TYPE INSTALL_DIR
    [[ ! -z ${1:-} ]] && TYPE=$1
    INSTALL_DIR=$BLACKBIRD_INSTALL_DIR
    
    type() {
        case "$TYPE" in
            "username")
                local value
                value=$(gum input --placeholder "What username?")
                if [[ -z $value ]]; then
                    _cleanup
                fi
                echo "--username $value" ;;
            "email")
                local value
                value=$(gum input --placeholder "What email?")
                if [[ -z $value ]]; then
                    _cleanup
                fi
                echo "--email $value" ;;
            *)
                echo "" ;;
        esac
    }
    output() {
        _gum confirm "Specify Output?"
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
        _gum confirm "Run verbose?"
        case $? in
            0) ;;
            1) return 0 ;;
            130) return 130 ;;
        esac
        echo "--verbose"
    }
    proxy() {
        _gum confirm "Use proxy?"
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
        _gum confirm "Remove NSFW results?"
        case $? in
            0) ;;
            1) return 0 ;;
            130) return 130 ;;
        esac
        echo "--no-nsfw"
    }
    extra_params() {
        _gum confirm "Add extra parameters?"
        case $? in
            0) ;;
            1) return 0 ;;
            130) return 130 ;;
        esac
        gum input --placeholder "Enter extra parameters" || return 130
    }

    if [[ ! -d $INSTALL_DIR ]] || [[ ! -f $LOCAL_INSTALL_BIN/blackbird ]] || [[ ! -f /etc/environment.d/99-blackbird.conf ]]; then
        if ! _install_blackbird; then
            printf "Could not install blackbird..."
        fi
    fi

    local TYPE_ARG OUTPUT_ARG VERBOSE_ARG PROXY_ARG NSFW_ARG EXTRA_ARG
    TYPE_ARG=$(type) || _cleanup
    OUTPUT_ARG=$(output) || _cleanup
    VERBOSE_ARG=$(verbose) || _cleanup
    PROXY_ARG=$(proxy) || _cleanup
    NSFW_ARG=$(nsfw) || _cleanup
    EXTRA_ARG=$(extra_params) || _cleanup

    echo "Outputs are stored in: $INSTALL_DIR/results"
    exec blackbird $TYPE_ARG $OUTPUT_ARG $VERBOSE_ARG $PROXY_ARG $NSFW_ARG $EXTRA_ARG
    exit 0
}

# ----------------------------------------- #
#               End Blackbird               #
# ----------------------------------------- #