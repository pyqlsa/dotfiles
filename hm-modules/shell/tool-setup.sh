# shellcheck disable=SC2148 # shebang skipped, file intended to be imported
# Depending on shell and system, either HOST or HOSTNAME is set
[[ -z ${HOSTNAME} ]] && HOSTNAME=${HOST}

# Keychain
# shellcheck disable=SC1090 # not worried about non-constant source
[[ -x $(which keychain) ]] \
  && $(which keychain) --nogui "${HOME}/.ssh/id_ed25519" \
  && source "${HOME}/.keychain/${HOSTNAME}-sh"

# Terraform completions
#[[ -x $(which terraform) ]] && \
#  complete -C $(which terraform) terraform
