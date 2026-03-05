_install() {
    local NAME TYPE REST
    NAME=$1
    TYPE=$2
    shift 2
    REST=$*

    case $TYPE in
        pkgmgr)
            if [[ -n $REST ]]; then
                _package_manager $NAME $REST
            else
                _package_manager $NAME
            fi
            ;;
        custom)
            case $NAME in
                blackbird)
                    _install_blackbird
                    ;;
            esac
            ;;
    esac
}

_add_self_to_path() {
    mkdir -p "$INSTALL_DIR"
    cp "$OSINTSH_SCRIPT_DIR/osint.sh" "$INSTALL_DIR/osint"
    chown $OSINTSH_ACTUAL_USER:$OSINTSH_ACTUAL_USER "$INSTALL_DIR/osint"
    chmod +x "$INSTALL_DIR/osint"
    # FIXME: printf "PATH=\"%s:\$PATH\"" $INSTALL_DIR:$LOCAL_INSTALL_BIN >> /etc/environment.d/99-osint.sh.conf
    printf "export PATH=\"%s:\$PATH\"" $INSTALL_DIR:$LOCAL_INSTALL_BIN >> "/home/$OSINTSH_ACTUAL_USER/.bashrc"
}