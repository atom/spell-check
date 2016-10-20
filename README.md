# Spell Check package
[![OS X Build Status](https://travis-ci.org/atom/spell-check.svg?branch=master)](https://travis-ci.org/atom/spell-check) [![Windows Build Status](https://ci.appveyor.com/api/projects/status/1620a5reqw6kdolv/branch/master?svg=true)](https://ci.appveyor.com/project/Atom/spell-check/branch/master) [![Dependency Status](https://david-dm.org/atom/spell-check.svg)](https://david-dm.org/atom/spell-check)

Highlights misspelling in Atom and shows possible corrections.

Use <kbd>cmd-shift-:</kbd> to bring up the list of corrections when your cursor is on a misspelled word.

By default spell check is enabled for the following files:

* Plain Text
* GitHub Markdown
* Git Commit Message
* AsciiDoc

You can override this from the _Spell Check_ settings in the Settings View (<kbd>cmd-,</kbd>). The Grammars config option is a list of scopes for which the package will check for spelling errors.

To enable _Spell Check_ for your current file type: put your cursor in the file, open the [Command Palette](https://github.com/atom/command-palette)
(<kbd>cmd-shift-p</kbd>), and run the `Editor: Log Cursor Scope` command. This will trigger a notification which will contain a list of scopes. The first scope that's listed is the one you should add to the list of scopes in the settings for the _Spell Check_ package. Here are some examples: `source.coffee`, `text.plain`, `text.html.basic`.

## Changing the dictionary

To change the language of the dictionary, set the "Locales" configuration option to the IETF tag (en-US, fr-FR, etc). More than one language can be used, simply separate them by commas.

For Windows 8 and 10, you must install the language using the regional settings before the language can be chosen inside Atom.

## Plugins

_Spell Check_ allows for plugins to provide additional spell checking functionality. See the `PLUGINS.md` file in the repository on how to write a plugin.
