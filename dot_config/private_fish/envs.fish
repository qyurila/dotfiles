set -gx EDITOR hx

# Use BitWarden SSH on WSL
if test -f /proc/sys/fs/binfmt_misc/WSLInterop
    set -gx GIT_SSH_COMMAND 'ssh.exe -F ~/.ssh/config'
end
