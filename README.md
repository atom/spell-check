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

## Writing Providers

The `spell-check` allows for additional dictionaries to be used at the same time using Atom's `providedServices` element in the `package.json` file.

    "providedServices": {
      "spell-check": {
        "versions": {
          "1.0.0": "nameOfFunctionToProvideSpellCheck"
        }
      }
    }

The `nameOfFunctionToProvideSpellCheck` function may return either a single object describing the spell-check plugin or an array of them. Each spell-check plugin must implement the following:

* getId(): string
    * This returns the canonical identifier for this plugin. Typically, this will be the package name with an optional suffix for options, such as `spell-check-project` or `spell-check:en-US`. This identifier will be used for some control plugins (such as `spell-check-project`) to enable or disable the plugin.
* getName(): string
    * Returns the human-readable name for the plugin. This is used on the status screen and in various dialogs/popups.
* getPriority(): number
    * Determines how significant the plugin is for information with lower numbers being more important. Typically, user-entered data (such as the config `knownWords` configuration or a project's dictionary) will be lower than system data (priority 100).
* isEnabled(): boolean
    * If this returns true, then the plugin will considered for processing.
* getStatus(): string
    * Returns a string that describes the current status or state of the plugin. This is to allow a plugin to identify why it is disabled or to indicate version numbers. This can be formatted for Markdown, including links, and will be displayed on a status screen (eventually).
* providesSpelling(buffer): boolean
    * If this returns true, then the plugin will be included when looking for incorrect and correct words via the `check` function.
* check(buffer, text: string): { correct: [range], incorrect: [range] }
    * `correct` and `incorrect` are both optional. If they are skipped, then it means the plugin does not contribute to the correctness or incorrectness of any word. If they are present but empty, it means there are no correct or incorrect words respectively.
    * The `range` objects have a signature of `{ start: X, end: Y }`.
* providesSuggestions(buffer): boolean
    * If this returns true, then the plugin will be included when querying for suggested words via the `suggest` function.
* suggest(buffer, word: string): [suggestion: string]
    * Returns a list of suggestions for a given word ordered so the most important is at the beginning of the list.
* providesAdding(buffer): boolean
    * If this returns true, then the dictionary allows a word to be added to the dictionary.
* getAddingTargets(buffer): [target]
    * Gets a list of targets to show to the user.
    * The `target` object has a minimum signature of `{ label: stringToShowTheUser }`. For example, `{ label: "Ignore word (case-sensitive)" }`.
    * This is a list to allow plugins to have multiple options, such as adding it as a case-sensitive or insensitive, temporary verses configuration, etc.
* add(buffer, target, word)
    * Adds a word to the dictionary, using the target for identifying which one is used.
