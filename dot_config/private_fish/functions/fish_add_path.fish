function fish_add_path --description 'Override: prepend to PATH persistently via ~/.bashrc (see path_add)'
    # Always prepends and persists, so -g/-U/-p/-m are accepted as no-ops.
    # -a, -P, -n and -v have no bashrc equivalent and are rejected.
    argparse -n fish_add_path g/global U/universal p/prepend m/move -- $argv
    or return

    # path_add prepends one at a time, so go in reverse to keep the given order.
    set -l failed 0
    for dir in $argv[-1..1]
        path_add $dir; or set failed 1
    end
    return $failed
end
