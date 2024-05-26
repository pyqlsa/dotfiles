# shellcheck disable=SC2148 # shebang skipped, file intended to be imported
# --- prompt ---
# https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
# adapted from: https://gist.github.com/romkatv/2a107ef9314f0d5f76563725b42f7cab

# Usage: prompt-length TEXT [COLUMNS]
function prompt-length() {
  emulate -L zsh
  local -i COLUMNS=${2:-COLUMNS}
  local -i x y=${#1} m
  if (( y )); then
    # shellcheck disable=SC2296,SC2298 # zsh valid parameter expansion
    while (( ${${(%):-$1%$y(l.1.0)}[-1]} )); do
      x=y
      (( y *= 2 ))
    done
    while (( y > x + 1 )); do
      (( m = x + (y - x) / 2 ))
      # shellcheck disable=SC2296,SC2298 # zsh valid parameter expansion
      (( ${${(%):-$1%$m(l.x.y)}[-1]} = m ))
    done
  fi
  typeset -g REPLY=$x
}

# Usage: fill-line LEFT RIGHT
#
# Sets REPLY to LEFT<spaces>RIGHT with enough spaces in
# the middle to fill a terminal line.
function fill-line() {
  emulate -L zsh
  prompt-length "$1"
  local -i left_len=REPLY
  prompt-length "$2" 9999
  local -i right_len=REPLY
  local -i pad_len=$((COLUMNS - left_len - right_len - ${ZLE_RPROMPT_INDENT:-1}))
  if (( pad_len < 1 )); then
    # Not enough space for the right part. Drop it.
    typeset -g REPLY=$1
  else
    # shellcheck disable=SC2296 # zsh valid parameter expansion
    local pad=${(pl.$pad_len.. .)}  # pad_len spaces
    typeset -g REPLY=${1}${pad}${2}
  fi
}

# Sets PROMPT and RPROMPT.
#
# Requires: prompt_percent and no_prompt_subst.
function set-prompt() {
  emulate -L zsh
  local git_branch
  git_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
  git_branch="${git_branch//\%/%%}"  # escape '%'
  git_branch=$([ -n "$git_branch" ] && echo " [${git_branch}]")

  local venv_info
  venv_info="$([ "${VIRTUAL_ENV}" ] && echo '('"$(basename "$VIRTUAL_ENV")"') ')"
  local nix_shell
  nix_shell="$([ -n "$IN_NIX_SHELL" ] && echo '(nix-shell) ')"

  # foo                              bar
  # > _                              baz
  #

  #PS1=$'%B%(?..[%?] )%b%n@%U%m%u> '
  #RPS1='%F{green}%~%f'

  local top_left="${venv_info}%F{magenta}${nix_shell}%f%F{cyan}%n%f@%U%F{blue}%m%f%u"
  local top_right="%F{green}%~%f%F{blue}${git_branch}%f"
  local bottom_left='%B%(?..[%?] )%b%(!.#.>)%f '
  local bottom_right=""

  local REPLY
  fill-line "$top_left" "$top_right"
  export PROMPT=$REPLY$'\n'$bottom_left
  export RPROMPT=$bottom_right
}

setopt no_prompt_{bang,subst} prompt_{cr,percent,sp}
autoload -Uz add-zsh-hook
add-zsh-hook precmd set-prompt
# --- end prompt ---
