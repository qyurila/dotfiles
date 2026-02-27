set -gx EDITOR hx

set -gx fzf_fd_opts --hidden

# Use BitWarden SSH on WSL
if test -f /proc/sys/fs/binfmt_misc/WSLInterop
    set -gx GIT_SSH_COMMAND 'ssh.exe -F ~/.ssh/config'
end
