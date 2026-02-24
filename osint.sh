#!/bin/bash

# ----------------------------- #
#   Made By Caden Finkelstein   #
# ----------------------------- #

GUM_CHOOSE_STYLE=""

start_blackbird() {
    TYPE=$1
    confirm() {
        gum confirm && return true || return false
    }
    type() {
        case "$TYPE" in
            "username")
                value=$(gum input --placeholder "What username?")
                echo "--username $value" ;;
            "email")
                value=$(gum input --placeholder "What email?")
                echo "--email $value" ;;
            *)
                echo "" ;;
        esac
    }
    output() {
        if gum confirm "Specify Output?"; then
            choice=$(gum choose $GUM_CHOOSE_STYLE "csv" "pdf" "json" "cancel")
            case "$choice" in
                "csv") echo "--csv" ;;
                "pdf") echo "--pdf" ;;
                "json") echo "--json" ;;
                "cancel") output ;;
            esac
        fi
    }
    verbose() {
        if gum confirm "Run verbose?"; then
            echo "--verbose"
        fi
    }
    proxy() {
        if gum confirm "Use proxy?"; then
            value=$(gum input --placeholder "Proxy URL?")
            echo "--proxy $value"
        fi
    }
    nsfw() {
        if gum confirm "Remove NSFW results?"; then
            echo "--no-nsfw"
        fi
    }
    extra_params() {
        if gum confirm "Add extra parameters?"; then
            gum input --placeholder "Enter extra parameters"
        fi
    }

    TYPE_ARG=$(type)
    OUTPUT_ARG=$(output)
    VERBOSE_ARG=$(verbose)
    PROXY_ARG=$(proxy)
    NSFW_ARG=$(nsfw)
    EXTRA_ARG=$(extra_params)

    clear
    blackbird $TYPE_ARG $OUTPUT_ARG $VERBOSE_ARG $PROXY_ARG $NSFW_ARG $EXTRA_ARG
    exit
}

username_menu() {
    while true; do
        if command -v gum > /dev/null; then
            choice=$(gum choose $GUM_CHOOSE_STYLE "Blackbird" "Back")
            clear
            case $choice in
                "Blackbird") start_blackbird "username" ;;
                "Back") clear && main_menu ;;
            esac
        fi
    done
}

email_menu() {
    while true; do
        if command -v gum > /dev/null; then
            choice=$(gum choose $GUM_CHOOSE_STYLE "Blackbird" "Back")
            clear
            case $choice in
                "Blackbird") start_blackbird "email" ;;
                "Back") clear && main_menu ;;
            esac
        fi
    done
}

main_menu() {
    while true; do
        if command -v gum > /dev/null; then
            choice=$(gum choose $GUM_CHOOSE_STYLE "Username" "Email" "Exit")
            clear
            case $choice in
                "Username") username_menu ;;
                "Email") email_menu ;;
                "Exit") clear && exit ;;
            esac
        else
            check() {
                YUM_CMD=$(which yum)
                APT_CMD=$(which apt)
                ZYPPER_CMD=$(which zypper)
                FEDORA_CMD=$(which dnf)
                NIX_CMD=$(which nix-env)
                ARCH_CMD=$(which pacman)
                FLOX_CMD=$(which flox)

                if [[ ! -z $YUM_CMD ]]; then
                    sudo yum install gum
                elif [[ ! -z $APT_CMD ]]; then
                    sudo mkdir -p /etc/apt/keyrings
                    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
                    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
                    sudo apt update && sudo apt install gum
                elif [[ ! -z $ZYPPER_CMD ]]; then
                    sudo zypper refresh
                    sudo zypper install gum
                elif [[ ! -z $FEDORA_CMD ]]; then
                    dnf install gum
                elif [[ ! -z $NIX_CMD ]]; then
                    nix-env -iA nixpkgs.gum
                elif [[ ! -z $ARCH_CMD ]]; then
                    pacman -S gum
                elif [[ ! -z $FLOX_CMD ]]; then
                    flox install gum
                else
                    if command -v brew > /dev/null; then
                        brew install gum
                    elif command -v go > /dev/null; then
                        go install github.com/charmbracelet/gum@latest
                    else
                        echo "error can't install gum :("
                        echo "Install from here: https://github.com/charmbracelet/gum"
                        exit 1;
                    fi
                fi
            }
            echo "Gum is not installed. You need it to use this program."
            echo "Do you want to install it?"
            select yn in "Yes" "No"; do
                case $yn in
                    Yes ) check ; break ;;
                    No ) exit ;;
                esac
            done
        fi
    done
}

main_menu
