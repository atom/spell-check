spellchecker = require 'spellchecker'
pathspec = require 'atom-pathspec'
env = require './checker-env'
debug = require 'debug'

# The locale checker is a checker that takes a locale string (`en-US`) and
# optionally a path and then checks it.
class LocaleChecker
  spellchecker: null
  locale: null
  enabled: true
  reason: null
  paths: null

  constructor: (locale, paths) ->
    @locale = locale
    @paths = paths
    @enabled = true
    @log = debug('spell-check:locale-checker').extend(locale)
    @log 'enabled', @isEnabled()

  deactivate: ->
    return

  getId: -> "spell-check:locale:" + @locale.toLowerCase().replace("_", "-")
  getName: -> "Locale Dictionary (" + @locale + ")"
  getPriority: -> 100 # Hard-coded system level data, has no user input.
  isEnabled: -> @enabled
  getStatus: -> @reason
  providesSpelling: (args) -> @enabled
  providesSuggestions: (args) -> @enabled
  providesAdding: (args) -> false

  check: (args, text) ->
    @deferredInit()
    id = @getId()
    if @enabled
      @spellchecker.checkSpellingAsync(text).then (incorrect) ->
        {id, invertIncorrectAsCorrect: true, incorrect}
    else
      {id, status: @getStatus()}

  suggest: (args, word) ->
    @deferredInit()
    @spellchecker.getCorrectionsForMisspelling(word)

  deferredInit: ->
    # The system checker is not enabled for Linux platforms (no built-in checker).
    if not @enabled
      @reason = "Darwin does not use locale-based checking without SPELLCHECKER_PREFER_HUNSPELL set."
      return

    # If we already have a spellchecker, then we don't have to do anything.
    if @spellchecker
      return

    # Initialize the spell checker which can take some time. We also force
    # the use of the Hunspell library even on Mac OS X. The "system checker"
    # is the one that uses the built-in dictionaries from the operating system.
    @spellchecker = new spellchecker.Spellchecker
    @spellchecker.setSpellcheckerType spellchecker.ALWAYS_USE_HUNSPELL

    # Build up a list of paths we are checking so we can report them fully
    # to the user if we fail.
    searchPaths = []

    # Windows uses its own API and the paths are unimportant, only attempting
    # to load it works.
    if env.isWindows()
      #if env.useWindowsSystemDictionary()
      #  return
      searchPaths.push "C:\\"

    # Check the paths supplied by the user.
    for path in @paths
      searchPaths.push pathspec.getPath(path)

    # For Linux, we have to search the directory paths to find the dictionary.
    if env.isLinux()
      searchPaths.push "/usr/share/hunspell"
      searchPaths.push "/usr/share/myspell"
      searchPaths.push "/usr/share/myspell/dicts"

    # OS X uses the following paths.
    if env.isDarwin()
      searchPaths.push "/"
      searchPaths.push "/System/Library/Spelling"

    # Try the packaged library inside the node_modules. `getDictionaryPath` is
    # not available, so we have to fake it. This will only work for en-US.
    searchPaths.push spellchecker.getDictionaryPath()

    # Attempt to load all the paths for the dictionary until we find one.
    @log 'checking paths', searchPaths
    for path in searchPaths
      if @spellchecker.setDictionary @locale, path
        @log 'found checker', path
        return

    # If we fell through all the if blocks, then we couldn't load the dictionary.
    @enabled = false
    @reason = "Cannot load the system dictionary for `" + @locale + "`."
    message = "The package `spell-check` cannot load the " \
      + "checker for `" \
      + @locale + "`." \
      + " See the settings for ways of changing the languages used, " \
      + " resolving missing dictionaries, or hiding this warning."

    searches = "\n\nThe plugin checked the following paths for dictionary files:\n* " \
      + searchPaths.join("\n* ")

    if not env.useLocales()
      searches = "\n\nThe plugin tried to use the system dictionaries to find the locale."

    noticesMode = atom.config.get('spell-check.noticesMode')

    if noticesMode is "console" or noticesMode is "both"
      console.log @getId(), (message + searches)
    if noticesMode is "popup" or noticesMode is "both"
      atom.notifications.addWarning(
        message,
        {
          buttons: [
            {
              className: "btn",
              onDidClick: -> atom.workspace.open("atom://config/packages/spell-check"),
              text: "Settings"
            }
          ]
        }
      )

module.exports = LocaleChecker
