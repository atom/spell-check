# Spell Check package
[![OS X Build Status](https://travis-ci.org/atom/spell-check.svg?branch=master)](https://travis-ci.org/atom/spell-check) [![Windows Build Status](https://ci.appveyor.com/api/projects/status/1620a5reqw6kdolv/branch/master?svg=true)](https://ci.appveyor.com/project/Atom/spell-check/branch/master) [![Dependency Status](https://david-dm.org/atom/spell-check.svg)](https://david-dm.org/atom/spell-check)

Highlights misspelling in Atom and shows possible corrections.

Use <kbd>cmd-shift-:</kbd> to bring up the list of corrections when your cursor is on a misspelled word.

By default spell check is enabled for the following files:

* Plain Text
* GitHub Markdown
* Git Commit Message
* AsciiDoc
* reStructuredText

You can override this from the _Spell Check_ settings in the Settings View (<kbd>cmd-,</kbd>). The Grammars config option is a list of scopes for which the package will check for spelling errors.

To enable _Spell Check_ for your current file type: put your cursor in the file, open the [Command Palette](https://github.com/atom/command-palette)
(<kbd>cmd-shift-p</kbd>), and run the `Editor: Log Cursor Scope` command. This will trigger a notification which will contain a list of scopes. The first scope that's listed is the one you should add to the list of scopes in the settings for the _Spell Check_ package. Here are some examples: `source.coffee`, `text.plain`, `text.html.basic`.

## Changing the dictionary

To change the language of the dictionary, set the "Locales" configuration option to the IETF tag (en-US, fr-FR, etc). More than one language can be used, simply separate them by commas.

### Missing Languages

This plugin uses the existing system dictionaries. If a locale is selected that is not installed, a warning will pop up when a document that would be spell-checked is loaded. To disable this, either remove the incorrect language from the "Locales" configuration or clear the check on "Use Locales" to disable it entirely.

To get the search paths used to look for a dictionary, make sure the "Notices Mode" is set to "console" or "both", then reload Atom. The developer's console will have the directory list.

#### Windows 8 and Higher

For Windows 8 and 10, this package uses the Windows spell checker, so you must install the language using the regional settings before the language can be chosen inside Atom.

![Windows 10 Language and Regions](docs/windows-10-language-settings.jpg)

Once the additional language is added, Atom will need to be restarted.

You can set the `SPELLCHECKER_PREFER_HUNSPELL` environment variable to request the use of the built-in hunspell spell checking library instead of the system dictionaries. If the environment variable is not set, then the `en-US` dictionaries found in the Atom's installation directory will not be used.

### Debian, Ubuntu, and Mint

On Ubuntu, installing "Language Support" may solve problems with the dictionaries. For other distributions (or if Language Support doesn't work), you may use `apt` to install the dictionaries.

```
sudo apt-get install hunspell-en-gb
sudo apt-get install myspell-en-gb
```

On RedHat, the following should work for Italian:

```
sudo dnf install hunspell
sudo dnf install hunspell-it
```

You can get a list of currently installed languages with:

```
/usr/bin/hunspell -D
```

Atom may require a restart to pick up newly installed dictionaries.

### Arch Linux

A language may be installed by running:

```
pacman -S hunspell-en_GB
```

For the time being, a soft link may be required if the dictionary provided is "large".

```
cd /usr/share/hunspell
sudo ln -s en_GB-large.dic en_GB.dic
sudo ln -s en_GB-large.aff en_GB.aff
```

## Plugins

_Spell Check_ allows for plugins to provide additional spell checking functionality. See the `PLUGINS.md` file in the repository on how to write a plugin.
