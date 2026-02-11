source ~/.config/fish/abbr.fish
source ~/.config/fish/envs.fish

mise activate fish | source
starship init fish | source
zoxide init fish | source

if status is-interactive
    # Commands to run in interactive sessions can go here
    eval (zellij setup --generate-auto-start fish | string collect)
end
