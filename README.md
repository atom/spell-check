# Spell Check Package [![Build Status](https://travis-ci.org/atom/spell-check.svg?branch=master)](https://travis-ci.org/atom/spell-check)

Highlights misspelling in Atom and shows possible corrections.

Use `cmd+shift+:` to bring up the list of corrections when your cursor is on a
misspelled word.

By default spell check is enabled for the following files:

* Plain Text
* GitHub Markdown
* Git Commit Message
* AsciiDoc

You can override this from the _Spell Check_ settings in the Settings view
(<kbd>cmd+,</kbd>). The Grammars config option is a list of scopes for which the package
will check for spelling errors.

To enable _Spell Check_ for your current file type: put your cursor in the file,
open the [Command Palette](https://github.com/atom/command-palette)
(<kbd>cmd+shift+p</kbd>), and run the `Editor: Log Cursor Scope` command. This
will trigger a notification which will contain a list of scopes. The first scope
that's listed is the one you should add to the list of scopes in the settings
for the _Spell Check_ package. Here are some examples: `source.coffee`,
`text.plain`, `text.html.basic`.

## Changing the dictionary

Currently, only the English (US) dictionary is supported. Follow [this issue](https://github.com/atom/spell-check/issues/11) for updates.
