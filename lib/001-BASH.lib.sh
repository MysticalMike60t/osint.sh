# ----------------------------------------- #
#          Bash Management Library          #
# ----------------------------------------- #

_cleanup() {
    clear

    echo -e "${ANSI_PURPLE}Bye Bye :3${ANSI_NC}"
    kill -INT $$ 2>/dev/null
} >&2

# ----------------------------------------- #
#        End Bash Management Library        #
# ----------------------------------------- #