verbose() {
    if [ -n "$VERBOSE" ]; then
        echo "$@" >&2
    fi
}
