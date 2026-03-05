_main_menu() {
    local PACKAGE_MANAGER
    PACKAGE_MANAGER=$(_package_manager check)
    while true; do
        if _command_exists gum; then
            local choice options
            options=("Username" "Email" "Exit")
            choice=$(_gum choose $GUM_CHOOSE_STYLE "${options[@]}") || _cleanup
            clear
            case $choice in
                "Username") _username_menu ;;
                "Email") _email_menu ;;
                "Exit") clear && exit ;;
            esac
        else
            _install_gum() {
                $VERBOSE && echo "Installing gum"
                case $PACKAGE_MANAGER in
                    apt)
                        $VERBOSE && echo "-> Using apt..."
                        mkdir -p /etc/apt/keyrings
                        curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg
                        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | tee /etc/apt/sources.list.d/charm.list
                        _install pkgmgr gum
                        ;;
                    yum)
                        $VERBOSE && echo "-> Using yum"
                        _install pkgmgr gum
                        ;;
                    zypper)
                        $VERBOSE && echo "-> Using zypper"
                        _install pkgmgr gum
                        ;;
                    dnf)
                        $VERBOSE && echo "-> Using dnf"
                        _install pkgmgr gum
                        ;;
                    nix-env)
                        $VERBOSE && echo "-> Using nix-env"
                        _install pkgmgr nixpkgs.gum
                        ;;
                    pacman)
                        $VERBOSE && echo "-> Using pacman"
                        _install pkgmgr gum
                        ;;
                    flox)
                        $VERBOSE && echo "-> Using flox"
                        _install pkgmgr gum
                        ;;
                    *)
                        $VERBOSE && _print color light-blue "-i]  Failed to use basic package managers, trying other ones...  [i-"
                        if _command_exists brew; then
                            $VERBOSE && echo "-> Using brew"
                            brew install gum
                        elif _command_exists go; then
                            $VERBOSE && echo "-> Using go"
                            go install github.com/charmbracelet/gum@latest
                        else
                            $VERBOSE && _print error simple 1 "Failed to install gum."
                            _print error simple 0 "error can't install gum :("
                            echo "Install from here: https://github.com/charmbracelet/gum"
                            $VERBOSE && _print error simple 0 "Exiting with error code 1..."
                            exit 1;
                        fi
                        ;;
                esac
            }
            echo "Gum is not installed. You need it to use this program."
            read -p "Do you want to install it? Type y/n?" yesorno
            case "$yesorno" in
                    y* | Y*)  _install_gum ;;
                    n* | N*)  echo "You need to install gum."; exit 1 ;;
            esac
        fi
    done
}