source ~/.config/fish/abbr.fish

if status is-interactive
    # Commands to run in interactive sessions can go here
end

mise activate fish | source
starship init fish | source
zoxide init fish | source
