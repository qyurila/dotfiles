function path_add --description 'Prepend a directory to PATH via ~/.bashrc, the single source for bash and fish'
    if test (count $argv) -ne 1
        echo "usage: path_add DIR" >&2
        return 2
    end

    set -l dir (path resolve -- $argv[1])
    if not test -d $dir
        echo "path_add: not a directory: $dir" >&2
        return 1
    end

    # Store home-relative paths as "$HOME/..." so bashrc stays portable.
    set -l entry $dir
    if string match -q -- "$HOME/*" $dir
        set entry (string replace -- $HOME '$HOME' $dir)
    end
    set -l line "    \"$entry\""

    if grep -qxF -- $line ~/.bashrc
        echo "path_add: already in ~/.bashrc: $entry"
        return 0
    end

    # Insert as the last (highest-priority) entry of the path_dirs array.
    set -l tmp (mktemp)
    env LINE=$line awk '
        /^path_dirs=\($/ { inarr = 1 }
        inarr && /^\)$/ { print ENVIRON["LINE"]; inarr = 0; done = 1 }
        { print }
        END { exit !done }
    ' ~/.bashrc >$tmp
    or begin
        rm -f $tmp
        echo "path_add: no path_dirs=( ... ) array found in ~/.bashrc" >&2
        return 1
    end

    cat $tmp >~/.bashrc # not mv: keeps permissions and any symlink
    rm -f $tmp

    # Apply to this session too; new shells pick it up from bashrc.
    fish_add_path -gm $dir
    echo "path_add: prepended $entry"
end
