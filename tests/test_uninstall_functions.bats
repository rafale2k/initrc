#!/usr/bin/env bats

setup() {
  # Mock HOME and DOTPATH with a temporary directory
  MOCK_DIR="$(mktemp -d)"
  export HOME="$MOCK_DIR"
  export DOTPATH="$MOCK_DIR/dotfiles"
  mkdir -p "$DOTPATH"

  # Source the script we are testing
  source "${BATS_TEST_DIRNAME}/../scripts/uninstall_functions.sh"
}

teardown() {
  rm -rf "$MOCK_DIR"
}


@test "remove_initrc_loader removes powerlevel10k config and .p10k.zsh" {
  # Mock bashrc and zshrc files
  cat << 'MOCK' > "$HOME/.bashrc"
# some normal bashrc line
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh # powerlevel10k
# another normal line
MOCK

  cat << 'MOCK' > "$HOME/.zshrc"
# some normal zshrc line
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
# another normal line
MOCK

  # Create mock .p10k.zsh
  touch "$HOME/.p10k.zsh"

  run remove_initrc_loader "$HOME"

  [ "$status" -eq 0 ]

  # Check output
  [[ "$output" == *"Final mop-up of Powerlevel10k leftovers..."* ]]
  [[ "$output" == *"Removed .p10k.zsh"* ]]

  # .p10k.zsh should be removed
  [ ! -f "$HOME/.p10k.zsh" ]

  # Check that offensive lines are removed, but normal ones are kept
  run cat "$HOME/.bashrc"
  [[ ! "$output" == *"powerlevel10k"* ]]
  [[ ! "$output" == *"p10k"* ]]
  [[ "$output" == *"# some normal bashrc line"* ]]
  [[ "$output" == *"# another normal line"* ]]

  run cat "$HOME/.zshrc"
  [[ ! "$output" == *"powerlevel10k"* ]]
  [[ ! "$output" == *"p10k"* ]]
  [[ ! "$output" == *"instant prompt"* ]]
  [[ "$output" == *"# some normal zshrc line"* ]]
  [[ "$output" == *"# another normal line"* ]]
}

@test "remove_initrc_symlinks removes standard dotfile symlinks pointing anywhere (based on current implementation)" {
  # Based on current implementation, dots are removed if they are just symlinks.
  # Let's create symlinks
  ln -s /dev/null "$HOME/.vimrc"
  ln -s /dev/null "$HOME/.gitconfig"
  ln -s /dev/null "$HOME/.inputrc"
  ln -s /dev/null "$HOME/.gitignore_global"
  ln -s /dev/null "$HOME/.nanorc"

  # Let's also create regular files to ensure they are NOT removed
  touch "$HOME/regular_file"
  # Let's mock a file with same name but not symlink (if we didn't ln it above)
  # Actually wait, we already created symlinks for all dots. Let's make one a regular file
  rm "$HOME/.nanorc"
  touch "$HOME/.nanorc"

  run remove_initrc_symlinks "$HOME"

  [ "$status" -eq 0 ]

  # Removed
  [ ! -L "$HOME/.vimrc" ]
  [ ! -L "$HOME/.gitconfig" ]
  [ ! -L "$HOME/.inputrc" ]
  [ ! -L "$HOME/.gitignore_global" ]

  # Preserved
  [ -f "$HOME/.nanorc" ]
  [ -f "$HOME/regular_file" ]
}

@test "remove_initrc_symlinks removes bin symlinks pointing to DOTPATH only" {
  mkdir -p "$HOME/bin"

  # regular file
  touch "$HOME/bin/my_script"

  # symlink pointing somewhere else
  ln -s /dev/null "$HOME/bin/other_symlink"

  # symlink pointing to DOTPATH
  ln -s "$DOTPATH/bin/initrc_script" "$HOME/bin/initrc_symlink"

  run remove_initrc_symlinks "$HOME"

  [ "$status" -eq 0 ]

  # Preserved
  [ -f "$HOME/bin/my_script" ]
  [ -L "$HOME/bin/other_symlink" ]

  # Removed
  [ ! -L "$HOME/bin/initrc_symlink" ]
}

@test "remove_initrc_symlinks removes oh-my-zsh custom plugins symlinks pointing to DOTPATH only" {
  local zsh_custom="$HOME/.oh-my-zsh/custom"
  mkdir -p "$zsh_custom/plugins"
  mkdir -p "$zsh_custom/themes"

  # Regular file
  touch "$zsh_custom/plugins/regular_plugin"

  # Symlink pointing somewhere else
  ln -s /dev/null "$zsh_custom/plugins/other_symlink"

  # Symlink pointing to DOTPATH
  ln -s "$DOTPATH/zsh/custom/plugins/initrc_plugin" "$zsh_custom/plugins/initrc_symlink"

  # Sub-directory symlink pointing to DOTPATH
  mkdir -p "$zsh_custom/themes/mytheme"
  ln -s "$DOTPATH/zsh/custom/themes/initrc_theme" "$zsh_custom/themes/mytheme/initrc_symlink"

  run remove_initrc_symlinks "$HOME"

  [ "$status" -eq 0 ]

  # Preserved
  [ -f "$zsh_custom/plugins/regular_plugin" ]
  [ -L "$zsh_custom/plugins/other_symlink" ]

  # Removed
  [ ! -L "$zsh_custom/plugins/initrc_symlink" ]
  [ ! -L "$zsh_custom/themes/mytheme/initrc_symlink" ]
}
