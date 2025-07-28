export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

plugins=(git zsh-autosuggestions zoxide fancy-ctrl-z zsh-syntax-highlighting zsh-autocomplete)

source $ZSH/oh-my-zsh.sh
alias n="nvim"
alias ll="lsa"
alias ls="eza --icons -1"
alias yy="brew install"
#plugins 
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"


