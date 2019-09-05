#!/bin/bash

# User defines FN_PATH to be ":"-separated list of directories to search, in order.
# If FN_PATH is empty, it is assumed to be "."


to_stderr() {
    (>&2 "$@")
}


# the function definition is enclosed in a subshell to allow the use of its own private
# library functions that won't also be exported to the namespace of the importing
# script
# global variables referenced: FN_PATH (default value "." if undefined or empty)
fn_import() {
    local option_force option_locate paths err
    declare -a fn_array
    until [ $# -eq 0 ]
    do
        case "$1" in
            --force|-f)
                option_force=yes
                shift
                ;;
            --locate|-l)
                option_locate=yes
                shift
                ;;
            *)
                fn_array+=("$1")
                shift
                ;;
        esac
    done
    paths=$(
        declare -a FN_PATH_ARRAY

        # split FN_PATH on ":" and populate the global FN_PATH_ARRAY so we only do this once
        # per invocation.
        fnpath_to_array() {
            local fnpath="$FN_PATH"
            if [ -z "$fnpath" ]; then
                fnpath=.
            fi
            mapfile -d : -t FN_PATH_ARRAY <<< "$fnpath"
        }
        trim() {
            local var="$*"
            # remove leading whitespace characters
            var="${var#"${var%%[![:space:]]*}"}"
            # remove trailing whitespace characters
            var="${var%"${var##*[![:space:]]}"}"   
            echo -n "$var"
        }
        to_stderr() {
            (>&2 "$@")
        }        
        fn_locate_in_path() {
            local file=$1
            local pathentry
            for pathentry in "${FN_PATH_ARRAY[@]}"
            do
                pathentry=$(trim "$pathentry")
                if [ -f "$pathentry/$file.sh" ]; then
                    echo "$pathentry/$file.sh"
                    return 0
                fi
            done
            to_stderr echo "error: file not found: $file"
            return 1
        }
        
        fn_locate() {
            local file found err=0
            for file in "${fn_array[@]}"
            do
                fn_locate_in_path $file 
                ((err+=$?))
            done
            if [ $err -gt 255 ]; then
                to_stderr echo "error: too many missing files: $err"
                err=255
            fi
            return $err
        }
        
        fnpath_to_array
        
        fn_locate "${fn_array[@]}"
        exit $?
    )
    err=$?
    if [ -n "$option_locate" ]; then
        echo "$paths"
    else
        if [ -n "$paths" ]; then
            source $paths
        fi
    fi
    return $err
}

# credit: https://stackoverflow.com/a/18839557/1347300
copy_function() {
  test -n "$(declare -f "$1")" || return 
  eval "${_/$1/$2}"
}

print_help() {
    echo "usage: source <(fn import) && import [--force|-f] lib1 lib2 ..."
    echo "usage: source <(fn import as import2) && import2 [--force|-f] lib1 lib2 ..."
    echo "usage: fn locate lib1 lib2 ..."
    echo "usage: fn --locate lib1 lib2 ..."
    echo "usage: fn -l lib1 lib2 ..."
}

# Main

if [ $# -eq 0 ]; then
    to_stderr print_help
    exit 1
fi

case "$1" in
    import)
        if [ -n "$2" ] && [ "$2" == "as" ] && [ -n "$3" ]; then
            import_name=$3
        else
            import_name=import
        fi
        copy_function fn_import $import_name
        declare -f $import_name
        exit 0
        ;;
    locate|--locate|-l)
        shift
        fn_import --locate "$@"
        exit $?
        ;;
    *)
        to_stderr print_help
        exit 1
        ;;
esac
