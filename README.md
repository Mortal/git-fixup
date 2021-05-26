git fixup
=========

`git commit --fixup`, but where you don't have to specify the correct commit.

Instead, this command runs `git blame` on the deleted lines to determine which commit to create a fixup commit for.

Installation
------------

`git clone https://github.com/Mortal/git-fixup`

`git config --global alias.fixup \!$PWD/git-fixup/git-fixup.sh`

Usage
-----

Create a fixup commit with all unstaged changes: `git fixup -a`

Run `git add -p` and create a fixup commit with the selected changes: `git fixup -p`

Create a fixup commit with the changes in a given file: `git add FILE ; git fixup`
