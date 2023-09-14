PROMPT='%F{green}%~»%b '

HISTFILE=~/.local/share/zhist
HISTSIZE=10000000
SAVEHIST=10000000
setopt appendhistory

autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit

bindkey -e
source $HOME/.config/shell/aliasrc
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
