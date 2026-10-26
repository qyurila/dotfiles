source ~/.config/fish/abbr.fish
source ~/.config/fish/envs.fish

# Import PATH from ~/.bashrc
set -l bash_path (bash -lc 'echo $PATH' 2>/dev/null | string split :)
test -n "$bash_path"; and set -gx PATH $bash_path

mise activate fish | source

atuin init fish | source
starship init fish | source
zoxide init fish | source

function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    command yazi $argv --cwd-file="$tmp"
    if read -z cwd <"$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end
