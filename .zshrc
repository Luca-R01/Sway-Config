# File: ~/.zshrc

# Personalizzazione del prompt con il nome del branch Git solo se presente
PROMPT='%F{#8ab4f8}%n@%m: %~$(git_branch) $> %F{reset}'

# History config
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

plugins=(
  history-substring-search
)

# Configurazione Zsh-completion
autoload -U compinit
compinit

# Git
autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )
setopt prompt_subst
zstyle ':vcs_info:git:*' formats '%b'

# Funzione per ottenere il nome del branch Git
git_branch() {
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ -n "$branch" ]]; then
    echo " ($branch)"
  fi
}
