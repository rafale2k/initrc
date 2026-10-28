# shellcheck shell=bash
# --- zsh/hooks.zsh ---

# プロンプトが表示される直前に実行
_my_precmd_hook() {
    # SC2154対策: Zsh固有の特殊変数 $functions を Shellcheck に無視させる
    # shellcheck disable=SC2154
    if (( $+functions[set_monokai_colors] )); then
        set_monokai_colors
    fi
}

# 既存のフックに追加
autoload -Uz add-zsh-hook
add-zsh-hook precmd _my_precmd_hook

# コマンド開始時刻を記録
_my_preexec_latency() {
    timer=${timer:-$SECONDS}
}

# コマンド終了時に差分を計算
_my_precmd_latency() {
    if [ "$timer" ]; then
        local now=$SECONDS
        local elapsed=$((now - timer))
        if (( elapsed >= 10 )); then
            export LATENCY_ALERT="🐢(${elapsed}s)"
        else
            export LATENCY_ALERT=""
        fi
        unset timer
    fi
}

add-zsh-hook preexec _my_preexec_latency
add-zsh-hook precmd _my_precmd_latency

# Optimization for zsh-syntax-highlighting path checker
# We override the function _zsh_highlight_main_highlighter_check_path after it is loaded
# by completely replacing its definition with an optimized version.
_patch_zsyh_path_checker() {
    # shellcheck disable=SC2154
    if (( $+functions[_zsh_highlight_main_highlighter_check_path] )) && [[ -z "$_ZSYH_PATH_CHECKER_PATCHED" ]]; then
        export _ZSYH_PATH_CHECKER_PATCHED=1

        # We override the function completely instead of using string replacements on function source
        # to prevent issues with spacing, escaping, or variable expansion in sed/awk.
        # We disable ShellCheck for this function because it uses zsh-specific syntax.
        # shellcheck disable=all
        function _zsh_highlight_main_highlighter_check_path() {
            _zsh_highlight_main_highlighter_expand_path "$1"
            local expanded_path="$REPLY" tmp_path
            integer in_command_position=$2

            if [[ $zsyh_user_options[autocd] == on ]]; then
                integer autocd=1
            else
                integer autocd=0
            fi

            if (( in_command_position )); then
                REPLY=arg0
            else
                REPLY=path
            fi

            if [[ ${1[1]} == '=' && $1 == ??* && ${1[2]} != $'\x28' && $zsyh_user_options[equals] == 'on' && $expanded_path[1] != '/' ]]; then
                REPLY=unknown-token # will error out if executed
                return 0
            fi

            [[ -z $expanded_path ]] && return 1

            # Check if this is a blacklisted path
            if [[ $expanded_path[1] == / ]]; then
                tmp_path=$expanded_path
            else
                tmp_path=$PWD/$expanded_path
            fi
            tmp_path=$tmp_path:a

            while [[ $tmp_path != / ]]; do
                [[ -n ${(M)ZSH_HIGHLIGHT_DIRS_BLACKLIST:#$tmp_path} ]] && return 1
                tmp_path=$tmp_path:h
            done

            if (( in_command_position )); then
                if [[ -x $expanded_path ]]; then
                if (( autocd )); then
                    if [[ -d $expanded_path ]]; then
                    REPLY=autodirectory
                    fi
                    return 0
                elif [[ ! -d $expanded_path ]]; then
                    return 0
                fi
                fi
            else
                if [[ -L $expanded_path || -e $expanded_path ]]; then
                return 0
                fi
            fi

            # Search the path in CDPATH (Optimized with Y1)
            if [[ $expanded_path != /* ]] && (( autocd || ! in_command_position )); then
                local -a tmp
                tmp=( $^cdpath/$expanded_path(N-/xY1) )
                if (( ${+tmp[1]} )); then
                    if (( in_command_position && autocd )); then
                        REPLY=autodirectory
                    fi
                    return 0
                fi
            fi

            # If dirname($1) doesn't exist, neither does $1.
            [[ ! -d ${expanded_path:h} ]] && return 1

            # If this word ends the buffer, check if it's the prefix of a valid path.
            # (Optimized with Y1)
            if (( has_end && (len == end_pos) )) && (( ! $#in_alias )) && [[ $WIDGET != zle-line-finish ]]; then
                local -a tmp
                if (( in_command_position )); then
                # We include directories even when autocd is enabled, because those
                # directories might contain executable files: e.g., BUFFER="/bi" en route
                # to typing "/bin/sh".
                tmp=( ${expanded_path}*(N-*,N-/Y1) )
                else
                tmp=( ${expanded_path}*(NY1) )
                fi
                (( ${+tmp[1]} )) && REPLY=path_prefix && return 0
            fi

            # It's not a path.
            return 1
        }
    fi
}
add-zsh-hook precmd _patch_zsyh_path_checker
