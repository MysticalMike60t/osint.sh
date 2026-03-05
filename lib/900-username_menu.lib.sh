_username_menu() {
    while true; do
        if _command_exists gum; then
            local choice options
            options=("Blackbird" "Back")
            choice=$(_gum choose $GUM_CHOOSE_STYLE "${options[@]}") || _cleanup
            clear
            case $choice in
                "Blackbird") _start_blackbird "username" ;;
                "Back") clear && _main_menu ;;
            esac
        fi
    done
}