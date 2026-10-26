set -gx EDITOR hx

set -gx SSH_AUTH_SOCK $HOME/.ssh/proton-pass-agent.sock
set -gx fzf_fd_opts --hidden

# Use BitWarden SSH on WSL
if test -f /proc/sys/fs/binfmt_misc/WSLInterop
    set -gx GIT_SSH_COMMAND 'ssh.exe -F ~/.ssh/config'
end

# Proton Pass CLI: keep login across WSL restarts (key stored on disk instead of kernel keyring)
set -gx PROTON_PASS_KEY_PROVIDER fs
