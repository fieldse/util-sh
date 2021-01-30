# Utils.sh

## Summary

A small library of bash utilities for improving system configuration and management scripts.

## Installation

**Install via Git in local project directory**

```sh
# Recommended: Create a /lib directory in your current project
# This will prevent the readme/etc from conflicting with your current project.
mkdir lib && cd lib

# Clone the library to your current directory (or lib directory)
git clone git@github.com:fieldse/util-sh.git .

# or clone via HTTPS:
# git clone https://github.com/fieldse/util-sh.git .

```

**_Better: Install to /usr/local/lib_**

```sh
# Create a directory in your /usr/local/[lib|bin|src] system dir and clone to there
cd /usr/local/lib/
sudo mkdir utilsh

# Clone
git clone git@github.com:fieldse/util-sh.git utilsh

# Source from its install location:
. /usr/local/lib/utilsh/util.sh

```

## Usage

1. Source the utils file in your terminal session or shell script

```sh
 . util.sh # Or wherever you have installed it: eg '. /usr/local/lib/utilsh/util.sh'
```

2. Use any function in the library.

```sh
fileExists readme.md
```

## Documentation

**Function documentation**

Functions should be self documenting and have reasonably self-explanatory names.
If you're unsure what something does, check the function comments in `util.sh`.

If you're still not sure how a function works, the best way to learn is play around in the console.

**Function usage**

Most functions will take one or two arguments, which should each be surrounded by quotes if they include spaces or special characters.

**Print status of a successful command**

```sh
  $ echo "this should succeed"
  $ printStatus "$?" "test echo works" # Note that "$?" refers to exit status of last command

  [+] test echo works                                                  [OK]

```

**Print status of a failed command**

```sh
  $ echo "this should fail" && cat noexists.txt > /dev/null 2&>1
  $ printStatus "$?" "cat noexists.txt"
  [+] cat noexists.txt                                                 [fail]

```

**What does \$? mean?**

"\$?" means the exit status of the last command. You'll see it's used heavily in these functions.

You can also store the state of the last command:

```sh
  $ echo "this should succeed" ; state=$?
  $ echo "do some other things..."
  $ printStatus "${state}" "test echo works" # Note that "$?" refers to exit status of last command
```

## Repository

https://github.com/fieldse/util-sh

## License

GNU GPLv3

https://choosealicense.com/licenses/gpl-3.0/

(tl;dr: Free for personal or commercial use or modification, except distribution closed-source versions. No liability for damages/accidents/fiery explosions.)

## Contact

Contact me at Github: https://github.com/fieldse

Or: leave a comment in a new issue at the project repository:
https://github.com/fieldse/util-sh/issues
