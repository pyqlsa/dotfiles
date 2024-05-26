# shellcheck disable=SC2148 # shebang skipped, file intended to be imported
# setup for nnn
export NNN_TERMINAL=alacritty
__nnn() {
  if [ -n "$TMUX" ]; then
    nnn -a "$@"
  else
    tmux -u new-session nnn -a "$@"
  fi
}
