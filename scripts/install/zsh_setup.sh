#!/bin/bash
# shellcheck disable=SC2148,SC1090,SC1091

setup_oh_my_zsh() {
    : "${DOTPATH:=$HOME/dotfiles}"

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    local custom_dir="$HOME/.oh-my-zsh/custom"
    mkdir -p "$custom_dir/themes" "$custom_dir/plugins"

    # powerlevel10k
    if [ -d "$DOTPATH/zsh/themes/powerlevel10k" ]; then
        ln -sfn "$DOTPATH/zsh/themes/powerlevel10k" "$custom_dir/themes/powerlevel10k"
    fi

    log_info "Linking Zsh plugins..."
    for p in zsh-autosuggestions zsh-syntax-highlighting history-search-multi-word; do
        if [ -d "$DOTPATH/zsh/plugins/$p" ]; then
            ln -sfn "$DOTPATH/zsh/plugins/$p" "$custom_dir/plugins/$p"
            log_success "Linked $p"
        else
            log_error "Plugin not found in $DOTPATH/zsh/plugins/$p"
        fi
    done
}
