# Theme with full path names and hostname
if [ $UID -eq 0 ]; then NCOLOR="red"; else NCOLOR="white"; fi

export SM_FG_COLOR="colour0"
export SM_BG_COLOR="colour105"
export SM_COLOR="magenta"

alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto'
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -lah'
alias llt='ls -lat'
alias ls='ls --color=auto'

setopt promptsubst

autoload -U add-zsh-hook

PROMPT_SUCCESS_COLOR=$fg[cyan]
PROMPT_FAILURE_COLOR=$fg[red]
PROMPT_VCS_INFO_COLOR=$fg[000]
PROMPT_PROMPT=$fg[green]

GIT_DIRTY_COLOR=$fg[magenta]
GIT_CLEAN_COLOR=$fg[green]
GIT_PROMPT_INFO=$fg[cyan]

ZSH_THEME_GIT_PROMPT_PREFIX="("
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$GIT_PROMPT_INFO%})"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$GIT_DIRTY_COLOR%}✘"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$GIT_CLEAN_COLOR%}✔"

ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%}✚%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[yellow]%}✹%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}✖%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[yellow]%}➜%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[green]%}═%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[yellow]%}✭%{$reset_color%}"

setopt promptsubst

autoload -U add-zsh-hook

PROMPT_SUCCESS_COLOR=$fg[cyan]
PROMPT_FAILURE_COLOR=$fg[red]
PROMPT_VCS_INFO_COLOR=$fg[000]
PROMPT_PROMPT=$fg[green]

GIT_DIRTY_COLOR=$fg[magenta]
GIT_CLEAN_COLOR=$fg[green]
GIT_PROMPT_INFO=$fg[cyan]

ZSH_THEME_GIT_PROMPT_PREFIX="("
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$GIT_PROMPT_INFO%})"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$GIT_DIRTY_COLOR%}✘"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$GIT_CLEAN_COLOR%}✔"

ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%}✚%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[yellow]%}✹%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}✖%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[yellow]%}➜%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[green]%}═%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[yellow]%}✭%{$reset_color%}"

function collapse_pwd {
	echo $(pwd | sed -e "s,^$HOME,~,")
}

smdev_git_prompt () {
	echo "%{$GIT_PROMPT_INFO%}$(git_prompt_info)%{$GIT_DIRTY_COLOR%}$(git_prompt_status)%{$reset_color%}"
}

smdev_hostcolor () {
	echo "%{$fg[$SM_COLOR]%}"
}

_LBRACK="%{$fg[white]%}[%{$reset_color%}"
_USER="%{$fg[$NCOLOR]%}%n%{$reset_color%}"
_RBRACK="%{$fg[white]%}]%{$reset_color%}"
_AT="%{$fg[white]%}@%{$reset_color%}"
_PATH="%{$fg[green]%}"

PROMPT='$_USER$_AT$(smdev_hostcolor)%M%{$reset_color%} $_LBRACK$_PATH$(collapse_pwd)%{$reset_color%}$_RBRACK $(smdev_git_prompt)$(smdev_hostcolor)%(!.#.>)%{$reset_color%} '
RPROMPT='%{$fg[white]%}%T%{$reset_color%}'
