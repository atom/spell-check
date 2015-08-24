# Spell Check Package [![Build Status](https://travis-ci.org/atom/spell-check.svg?branch=master)](https://travis-ci.org/atom/spell-check)

Highlights misspelling in Atom and shows possible corrections.

Use `cmd+shift+:` to bring up the list of corrections when your cursor is on a
misspelled word.

By default spell check is enabled for the following files:

* Plain Text
* GitHub Markdown
* Git Commit Message

You can override this from the _Spell Check_ settings in the Settings view
(`cmd-,`).

To enable `spell-check` for your current file type: put your cursor in the file, open the *Command Palette* (Cmd+Shift+P) and open **Editor: Log Cursor Scope**.

## Changing the dictionary

Currently, only the English (US) dictionary is supported. Follow [this issue](https://github.com/atom/spell-check/issues/11) for updates.
