Import Function
===============

# Summary

This package provides a simple wrapper around the `source` command to import
shell scripts from directories specified in an environment variable `FN_PATH`,
instead of providing absolute or relative paths to scripts or managing the
same path variables in every script. 

# Quick install with curl

Download and install the script:

```
curl --silent --show-error -o /usr/bin/fn https://raw.githubusercontent.com/jbuhacoff/bash-fn-import/master/src/main/script/fn.sh
chmod 755 /usr/bin/fn
```

# Quick install with git

Clone the repository and install the script:

```
git clone https://github.com/jbuhacoff/bash-fn-import.git
cp bash-fn-import/src/main/script/rs.sh /usr/bin/rs
chmod 755 /usr/bin/rs
```

# Configure

Create your own script directory and initialize the shell with `FN_PATH`
each time you login, and also in the current session:

```
mkdir -p /etc/profile.d /usr/share/fn
cat >/etc/profile.d/fn_path.sh <<'EOF'
#!/bin/sh
export FN_PATH=/usr/share/fn
EOF
source /etc/profile.d/fn_path.sh
```

# Example 

Consider this directory listing:

* lib/verbose.sh
* script1.sh
* script2.sh

Content of `lib/verbose.sh`:

```
verbose() {
    if [ -n "$VERBOSE" ]; then
        echo "$@" >&2
    fi
}
```

Content of `script1.sh`:

```
#!/bin/bash

source <(fn import)
import lib/verbose

VERBOSE=yes
verbose hello script1
```

Content of `script2.sh`:

```
#!/bin/bash

source <(fn import)
import lib/verbose

VERBOSE=yes
verbose hello script2
```

When you run `script1` and `script2` they both import the `verbose` function
from the `lib/verbose.sh` file.

# Search path

To customize the search path, export `FN_PATH` with a `:`-separated list of 
directories to search:

```
export FN_PATH=/path/to/lib1:/path/to/lib2
```

The directories will be searched in the order specified in `FN_PATH` and the
first match will be used.

# Locate a file

If it seems the wrong library or the wrong version of a library is being loaded,
you can check it with the `locate` option on the command line:

```
fn --locate <lib>
fn -l <lib>
```

It will print out the path wherever `<lib>` is found and exit 0, or it will print
an error message to stderr and exit with a non-zero status. If you specify more than
one item on the command line to search, the exit code is 0 only if all were found
(and all the paths are printed to stdout). If not all were found, the exit code
reflects the number of items not found up to 255 missing items.

# Rename import function

If your script already has an `import` function or your system already has an `import`
command and you need to avoid a name clash, you can rename the `import` function.

Consider this example:

```
#!/bin/bash

source <(fn import as import_from)
import_from lib/verbose

VERBOSE=yes
verbose hello script3
```

