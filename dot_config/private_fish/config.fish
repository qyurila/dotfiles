source ~/.config/fish/abbr.fish
source ~/.config/fish/envs.fish

if status is-interactive
    # Commands to run in interactive sessions can go here
end

mise activate fish | source
starship init fish | source
zoxide init fish | source
