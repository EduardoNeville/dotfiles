TmuxSessionInit()
{
    declare sessionName="$1";
    shift;

    # Check if the Tmux session exists
    if ! tmux has-session -t="$sessionName" 2> '/dev/null';
    then
        # Create the Tmux session
        TMUX='' tmux new-session -ds "$sessionName";
    fi

    # Switch if inside of Tmux
    if [[ "${TMUX-}" != '' ]];
    then
        exec tmux switch-client -t "$sessionName";
    fi

    # Attach if outside of Tmux
    exec tmux attach -t "$sessionName";
}

TmuxSessionInit '0';

