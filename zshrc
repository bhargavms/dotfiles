# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Homebrew (only if installed)
if command -v brew &> /dev/null; then
    eval "$(brew shellenv)"
elif [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Function to discover Google Cloud SDK installation
discover_gcloud_sdk() {
  local possible_paths=(
    "$HOME/google-cloud-sdk"
    "/usr/local/share/google-cloud-sdk"
    "/opt/google-cloud-sdk"
    "/usr/share/google-cloud-sdk"
    "/Applications/google-cloud-sdk"
    "$HOME/.local/share/google-cloud-sdk"
    "$HOME/Library/google-cloud-sdk"
  )
  
  for path in "${possible_paths[@]}"; do
    if [[ -d "$path" && -f "$path/bin/gcloud" ]]; then
      echo "$path"
      return 0
    fi
  done
  
  # If not found in common locations, try to find via which gcloud
local gcloud_path=$(which gcloud 2>/dev/null)
  if [[ -n "$gcloud_path" ]]; then
    local sdk_path="${gcloud_path%/*}"  # Remove filename
    sdk_path="${sdk_path%/*}"           # Remove bin directory
    if [[ -d "$sdk_path" && -f "$sdk_path/bin/gcloud" ]]; then
      echo "$sdk_path"
      return 0
    fi
  fi
  
  return 1
}
# Set CLOUDSDK_HOME environment variable
export CLOUDSDK_HOME=$(discover_gcloud_sdk)

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$HOME/Library/Android/sdk/platform-tools:$PATH
# Only add to PATH if CLOUDSDK_HOME is set and valid
if [[ -n "$CLOUDSDK_HOME" && -d "$CLOUDSDK_HOME/bin" ]]; then
  export PATH=$CLOUDSDK_HOME/bin:$PATH
fi
export PATH=$HOME/.local/share/nvim/mason/bin:$PATH
export ANDROID_HOME=$HOME/Library/Android/sdk
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git gcloud kubectl kubectx kops macos minikube)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
alias zshconfig="nvim ~/.zshrc"
alias ohmyzsh="nvim ~/.oh-my-zsh"
alias applyzshconfig="source ~/.zshrc"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

typeset -g POWERLEVEL9K_GCLOUD_COMPLETE_CONTENT_EXPANSION='${P9K_GCLOUD_ACCOUNT} @ ${P9K_GCLOUD_PROJECT_NAME//\%/%%}'

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
export LDFLAGS="-L$HOME/local/lib"
export CPPFLAGS="-I$HOME/local/include"
export PKG_CONFIG_PATH="$HOME/local/lib/pkgconfig:$PKG_CONFIG_PATH"

export GOROOT=$HOME/.local/go/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
export GOROOT=$HOME/.local/go/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
export PATH=$PATH:$HOME/.local/bin
export LUA_PATH='$HOME/.local/share/lua/5.4.6/?.lua;$HOME/.local/share/lua/5.4.6/?/init.lua;'
export LUA_CPATH='$HOME/.local/lib/lua/5.4.6/?.so;'

export SDKMAN_DIR="$(brew --prefix sdkman-cli)/libexec"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

