# ----------------------------------------- #
#         Entry Variable Definitions        #
# ----------------------------------------- #

# Static strings
readonly TITLE="OSINT.sh"

declare -i ERRORS=0
declare -i VERBOSE=1
declare -lu LOG_FILE="/home/${OSINTSH_ACTUAL_USER}/osint.sh.log"
declare -lu INSTALL_DIR="/home/$OSINTSH_ACTUAL_USER/.local/share/osint.sh"
declare -lu LOCAL_INSTALL_BIN="/home/$OSINTSH_ACTUAL_USER/.local/bin"
declare -lu BLACKBIRD_INSTALL_DIR="/home/$OSINTSH_ACTUAL_USER/.local/share/blackbird"
# Initial arg variable values
declare -lu SCRIPT_ARGS_INSTALL_DIR=$INSTALL_DIR
declare -i SCRIPT_ARGS_CUSTOM_LOG_OUTPUT_ENABLED=1
declare -lu SCRIPT_ARGS_CUSTOM_LOG_OUTPUT_LOCATION=$LOG_FILE
declare -i SCRIPT_ARGS_VERBOSE_ENABLED=1
declare -i SCRIPT_ARGS_NO_INSTALL_ENABLED=1
declare -lu SCRIPT_ARGS_BLACKBIRD_INSTALL_DIR=$BLACKBIRD_INSTALL_DIR
declare -lu SCRIPT_ARGS_LOCAL_INSTALL_BIN=$LOCAL_INSTALL_BIN

export PATH="$LOCAL_INSTALL_BIN:$PATH"

# ----------------------------------------- #
#       End Entry Variable Definitions      #
# ----------------------------------------- #