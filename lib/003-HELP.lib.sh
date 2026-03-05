_usage() {
    local DISPLAY_NAME
    DISPLAY_NAME=$(_print color light-purple ${0#$OSINTSH_SCRIPT_DIR/})

    echo -e "Usage: $DISPLAY_NAME $(_print color yellow "[")OPTIONS$(_print color yellow "]")"
    echo -e "Options:"
    echo -e " $(_print color light-cyan "help"), $(_print color light-cyan "-h"), $(_print color light-cyan "--help")      Display this help message"
    echo -e " $(_print color light-cyan "-v"), $(_print color light-cyan "--verbose")         Enable verbose mode"
    echo -e " $(_print color light-cyan "init"), $(_print color light-cyan "-i"), $(_print color light-cyan "--init")      Initialize $(_print color light-purple "$TITLE") by adding it to $(_print color light-blue "PATH"), and installing"
    echo -e " $(_print color light-cyan "--insane-verbose")      Verbose on everything possible "
    echo -e " $(_print color light-cyan "-n"), $(_print color light-cyan "--no-install")      Don't install non-installed packages and/or programs"
    echo -e " $(_print color light-cyan "-l"), $(_print color light-cyan "--log")             Enable logs"
    echo -e " $(_print color light-cyan "--log-output")          Specify location of log output file"
    echo -e " $(_print color light-cyan "--blackbird-dir")       Specify directory of $(_print color light-green "Blackbird") installation"
    echo -e " $(_print color light-cyan "--local-install-bin")   Specify where you want the bin files to be placed"
    echo -e " $(_print color light-cyan "--install-dir")         Specify installation directory for $DISPLAY_NAME"
}