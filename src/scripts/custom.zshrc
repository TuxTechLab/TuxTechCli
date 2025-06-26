# ==============================================================================
# TuxTechLab Zsh Configuration
# ==============================================================================
#
# This is a custom zsh configuration file that works with zsh4humans.
# It's automatically managed by the TuxTechLab setup script.
#
# To customize your shell, you can:
# 1. Edit this file directly
# 2. Create a ~/.zshrc.local file for personal customizations
# 3. Add files to ~/.zsh/ directory and source them from here
#
# Documentation: https://github.com/romkatv/zsh4humans/blob/v5/README.md
# ==============================================================================

# Start zprof for profiling zsh startup time
# Uncomment to enable:
# zmodload zsh/zprof

# Periodic auto-update on Zsh startup: 'ask' or 'no'.
# You can manually run `z4h update` to update everything.
zstyle ':z4h:' auto-update      'no'
# Ask whether to auto-update this often; has no effect if auto-update is 'no'.
zstyle ':z4h:' auto-update-days '28'

# Keyboard type: 'mac' or 'pc'.
zstyle ':z4h:bindkey' keyboard  'pc'

# Start tmux if not already in tmux.
zstyle ':z4h:' start-tmux command tmux -u new -A -D -t tmux

# Whether to move prompt to the bottom when zsh starts and on Ctrl+L.
zstyle ':z4h:' prompt-at-bottom 'no'

# Mark up shell's output with semantic information.
zstyle ':z4h:' term-shell-integration 'yes'

# Right-arrow key accepts one character ('partial-accept') from
# command autosuggestions or the whole thing ('accept')?
zstyle ':z4h:autosuggestions' forward-char 'accept'

# Recursively traverse directories when TAB-completing files.
zstyle ':z4h:fzf-complete' recurse-dirs 'no'

# Enable direnv to automatically source .envrc files.
zstyle ':z4h:direnv'         enable 'yes'
# Show "loading" and "unloading" notifications from direnv.
zstyle ':z4h:direnv:success' notify 'yes'

# Enable ('yes') or disable ('no') automatic teleportation of z4h over
# SSH when connecting to these hosts.
zstyle ':z4h:ssh:example-hostname1'   enable 'yes'
zstyle ':z4h:ssh:*.example-hostname2' enable 'no'
# The default value if none of the overrides above match the hostname.
zstyle ':z4h:ssh:*'                   enable 'no'

# Send these files over to the remote host when connecting over SSH to the
# enabled hosts.
zstyle ':z4h:ssh:*' send-extra-files '~/.nanorc' '~/.env.zsh'

# Start ssh-agent if it's not running yet.
zstyle ':z4h:ssh-agent:' start yes

# Clone additional Git repositories from GitHub.
#
# This doesn't do anything apart from cloning the repository and keeping it
# up-to-date. Cloned files can be used after `z4h init`. This is just an
# example. If you don't plan to use Oh My Zsh, delete this line.
z4h install ohmyzsh/ohmyzsh || return

# Install or update core components (fzf, zsh-autosuggestions, etc.) and
# initialize Zsh. After this point console I/O is unavailable until Zsh
# is fully initialized. Everything that requires user interaction or can
# perform network I/O must be done above. Everything else is best done below.
z4h init || return

# Extend PATH.
path=(~/bin $path)

# Export environment variables.
export GPG_TTY=$TTY

# Source additional local files if they exist.
z4h source ~/.env.zsh

# Use additional Git repositories pulled in with `z4h install`.
#
# This is just an example that you should delete. It does nothing useful.
z4h source ohmyzsh/ohmyzsh/lib/diagnostics.zsh  # source an individual file
z4h load   ohmyzsh/ohmyzsh/plugins/emoji-clock  # load a plugin

# Define key bindings.
z4h bindkey z4h-backward-kill-word  Ctrl+Backspace     Ctrl+H
z4h bindkey z4h-backward-kill-zword Ctrl+Alt+Backspace

z4h bindkey undo Ctrl+/ Shift+Tab  # undo the last command line change
z4h bindkey redo Alt+/             # redo the last undone command line change

z4h bindkey z4h-cd-back    Alt+Left   # cd into the previous directory
z4h bindkey z4h-cd-forward Alt+Right  # cd into the next directory
z4h bindkey z4h-cd-up      Alt+Up     # cd into the parent directory
z4h bindkey z4h-cd-down    Alt+Down   # cd into a child directory

# Autoload functions.
autoload -Uz zmv

# Define functions and completions.
function md() { [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1" }
compdef _directories md

# Define named directories: ~w <=> Windows home directory on WSL.
[[ -z $z4h_win_home ]] || hash -d w=$z4h_win_home

function cheat(){
    if [ -z $1 ]; then
       echo "Please pass a command name."
       echo ""
       echo "EXAMPLE: "
       echo "$> cheat ls"
    else
       curl cheat.sh/$1 | lolcat -f
    fi
}

function weather(){
    if [ -z $1 ]; then
       echo "Please pass a station name to check weather."
       echo ""
       echo "EXAMPLE: "
       echo "$> weather delhi"
    else
       curl "wttr.in/"$1
    fi
}

function fast-nmap(){
    if [ -z $1 ]; then
       echo "Please pass a IP Address/ DNS Name"
       echo ""
       echo "EXAMPLE: "
       echo "$> fast-nmap localhost"
    else
       nmap --top-ports=100 -v -oG - --reason $1
    fi
}
function fast-nmap-subnet-scan(){
    if [ -z $1 ]; then
       echo "Please provide valid subnet address."
       echo ""
       echo "EXAMPLE: "
       echo "$> fast-nmap-subnet-scan 192.168.1.1/24"
   else
      nmap -T4 --open -F $1
   fi
}

# Define aliases.
alias tree='tree -a -I .git'
#alias docker='podman'


# Add flags to existing aliases.
# Add -A to ls alias to show hidden files (except . and ..)
alias ls="${aliases[ls]:-ls} -A"

# ==============================================================================
# Zsh Options
# ==============================================================================
# Set shell options: http://zsh.sourceforge.net/Doc/Release/Options.html
setopt glob_dots           # no special treatment for file names with a leading dot
setopt no_auto_menu        # require an extra TAB press to open the completion menu
setopt auto_cd             # cd by typing directory name if it's not a command
setopt extended_glob       # use extended globbing features
setopt interactive_comments # allow comments in interactive shell
setopt no_beep             # don't beep on error
setopt no_case_glob        # case-insensitive globbing
setopt numeric_glob_sort   # sort filenames numerically when it makes sense

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt append_history       # append to history file instead of overwriting
setopt extended_history     # save timestamp and duration to history
setopt hist_expire_dups_first # expire duplicate entries first
setopt hist_ignore_dups     # don't store duplicate entries
setopt hist_ignore_space    # don't store commands starting with space
setopt hist_verify          # show command with history expansion to user before running it
setopt share_history        # share history between terminal sessions

# ==============================================================================
# Environment Variables
# ==============================================================================
# Set default editor
if command -v nvim >/dev/null 2>&1; then
    export EDITOR='nvim'
elif command -v vim >/dev/null 2>&1; then
    export EDITOR='vim'
else
    export EDITOR='vi'
fi

# Set pager
if command -v bat >/dev/null 2>&1; then
    export PAGER='bat --paging=always --style=plain'
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export MANROFFOPT="-c"
else
    export PAGER='less -RFX'
fi

# Add ~/bin to PATH if it exists
[ -d "$HOME/bin" ] && export PATH="$HOME/bin:$PATH"

# Add ~/.local/bin to PATH if it exists
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

# ==============================================================================
# Aliases
# ==============================================================================
# Enable color support for various commands
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Common aliases
alias ll='ls -alFh'
alias la='ls -A'
alias l='ls -CF'
alias c='clear'
alias h='history'
alias j='jobs -l'
alias path='echo -e ${PATH//:/\n}'
alias now='date +"%T"'
alias nowtime='now'
alias nowdate='date +"%d-%m-%Y"'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit -v'
alias gcm='git commit -m'
alias gco='git checkout'
alias gd='git diff'
alias gl='git pull'
alias gp='git push'
alias grh='git reset --hard'
alias gst='git status'

# Safety features
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# ==============================================================================
# Functions
# ==============================================================================
# Create a new directory and enter it
mkd() {
    mkdir -p "$@" && cd "${@: -1}" || return
}

# Change working directory to the top-most Finder window location
cdf() { # short for `cdfinder`
    cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)' 2>/dev/null)" || return
}

# Create a .tar.gz archive, using `zopfli`, `pigz` or `gzip` for compression
targz() {
    local tmpFile="${1%/}.tar"
    tar -cvf "${tmpFile}" --exclude=".DS_Store" "${1}" || return 1
    
    size=$(
        stat -f"%z" "${tmpFile}" 2>/dev/null || # macOS `stat`
        stat -c"%s" "${tmpFile}"              # GNU `stat`
    )
    
    local cmd=""
    if (( size < 52428800 )) && hash zopfli 2>/dev/null; then
        # the .tar file is smaller than 50 MB and Zopfli is available
        cmd="zopfli"
    else
        if hash pigz 2>/dev/null; then
            cmd="pigz"
        else
            cmd="gzip"
        fi
    fi
    
    echo "Compressing .tar using ${cmd}…"
    "${cmd}" -v "${tmpFile}" || return 1
    [ -f "${tmpFile}" ] && rm "${tmpFile}"
    echo "${tmpFile}.gz created successfully."
}

# ==============================================================================
# Load local configuration
# ==============================================================================
# Source local zsh config if it exists
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# Source zsh-syntax-highlighting if it exists
if [ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Source zsh-autosuggestions if it exists
if [ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
    # Enable async autosuggestions
    ZSH_AUTOSUGGEST_USE_ASYNC=1
fi

# ==============================================================================
# Finalize
# ==============================================================================
# End zprof if it was started
if (($+zprof)); then
    zprof
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# get load averages
IFS=" " read LOAD1 LOAD5 LOAD15 <<<$(cat /proc/loadavg | awk '{ print $1,$2,$3 }')
# get free memory
IFS=" " read USED AVAIL TOTAL <<<$(free -htm | grep "Mem" | awk {'print $3,$7,$2'})
# get processes
PROCESS=`ps -eo user=|sort|uniq -c | awk '{ print $2 " " $1 }'`
PROCESS_ALL=`echo "$PROCESS"| awk {'print $2'} | awk '{ SUM += $1} END { print SUM }'`
PROCESS_ROOT=`echo "$PROCESS"| grep root | awk {'print $2'}`
PROCESS_USER=`echo "$PROCESS"| grep -v root | awk {'print $2'} | awk '{ SUM += $1} END { print SUM }'`
# get processors
PROCESSOR_NAME=`grep "model name" /proc/cpuinfo | cut -d ' ' -f3- | awk {'print $0'} | head -1`
PROCESSOR_COUNT=`grep -ioP 'processor\t:' /proc/cpuinfo | wc -l`

W="\e[0;39m"
G="\e[1;32m"

neofetch --source /etc/motd2

echo -e "Current User: $(whoami)\nHost: $(hostname)" | lolcat -f
echo -e "
${W}system info:
$W  Distro......: $W`cat /etc/*release | grep "PRETTY_NAME" | cut -d "=" -f 2- | sed 's/"//g'`
$W  Kernel......: $W`uname -sr`

$W  Uptime......: $W`uptime -p`
$W  Load........: $G$LOAD1$W (1m), $G$LOAD5$W (5m), $G$LOAD15$W (15m)
$W  Processes...:$W $G$PROCESS_ROOT$W (root), $G$PROCESS_USER$W (user), $G$PROCESS_ALL$W (total)

$W  CPU.........: $W$PROCESSOR_NAME ($G$PROCESSOR_COUNT$W vCPU)
$W  Memory......: $G$USED$W used, $G$AVAIL$W avail, $G$TOTAL$W total$W"

tmux ls | lolcat -f

export GPG_TTY=$(tty)
