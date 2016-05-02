# Plugins

The `spell-check` allows for additional dictionaries to be used at the same time using Atom's `providedServices` element in the `package.json` file.

    "providedServices": {
      "spell-check": {
        "versions": {
          "1.0.0": "nameOfFunctionToProvideSpellCheck"
        }
      }
    }

The `nameOfFunctionToProvideSpellCheck` function may return either a single `require`able path or an array of them. This must be an absolute path to a class that provides a checker instance (below).

    provideSpellCheck: ->
      require.resolve './project-checker.coffee'

The path given must resolve to a singleton instance of a class.

    class ProjectChecker
      # Magical code
    checker = new ProjectChecker()
    module.exports = checker

See the `spell-check-project` for an example implementation.

# Checker

A common parameter type is `checkArgs`, this is a hash with the following signature.

    args = {
      projectPath: "/absolute/path/to/project/root,
      relativePath: "relative/path/from/projet/root"
    }

Below the required methods for the checker instance.

* getId(): string
    * This returns the canonical identifier for this plugin. Typically, this will be the package name with an optional suffix for options, such as `spell-check-project` or `spell-check:en-US`. This identifier will be used for some control plugins (such as `spell-check-project`) to enable or disable the plugin.
     * This will also used to pass information from the Atom process into the background task once that is implemented.
* getPriority(): number
    * Determines how significant the plugin is for information with lower numbers being more important. Typically, user-entered data (such as the config `knownWords` configuration or a project's dictionary) will be lower than system data (priority 100).
* isEnabled(): boolean
    * If this returns true, then the plugin will considered for processing.
* providesSpelling(checkArgs): boolean
    * If this returns true, then the plugin will be included when looking for incorrect and correct words via the `check` function.
* checkArray(checkArgs, words: string[]): boolean?[]
    * This takes an array of words in a given line. This will be called once for every line inside the buffer. It also also not include words already requested earlier in the buffer.
    * The output is an array of the same length as words which has three values, one for each word given:
        * `null`: The checker provides no opinion on correctness.
        * `false`: The word is specifically false.
        * `true`: The word is correctly spelled.
    * True always takes precedence, then false. If every checker provides `null`, then the word is considered spelled correctly.
* providesSuggestions(checkArgs): boolean
    * If this returns true, then the plugin will be included when querying for suggested words via the `suggest` function.
* suggest(checkArgs, word: string): [suggestion: string]
    * Returns a list of suggestions for a given word ordered so the most important is at the beginning of the list.
* providesAdding(checkArgs): boolean
    * If this returns true, then the dictionary allows a word to be added to the dictionary.
* getAddingTargets(checkArgs): [target]
    * Gets a list of targets to show to the user.
    * The `target` object has a minimum signature of `{ label: stringToShowTheUser }`. For example, `{ label: "Ignore word (case-sensitive)" }`.
    * This is a list to allow plugins to have multiple options, such as adding it as a case-sensitive or insensitive, temporary verses configuration, etc.
* add(buffer, target, word)
    * Adds a word to the dictionary, using the target for identifying which one is used.
