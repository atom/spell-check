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
  checkDictionaryPath: true
  checkDefaultPaths: true

  constructor: (locale, paths, hasSystemChecker, inferredLocale) ->
    @locale = locale
    @paths = paths
    @enabled = true
    @hasSystemChecker = hasSystemChecker
    @inferredLocale = inferredLocale
    @log = debug('spell-check:locale-checker').extend(locale)
    @log 'enabled', @isEnabled(), 'hasSystemChecker', @hasSystemChecker, 'inferredLocale', @inferredLocale

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
      @spellchecker.checkSpellingAsync(text).then (incorrect) =>
        if @log.enabled
          @log 'check', incorrect
        {id, invertIncorrectAsCorrect: true, incorrect}
    else
      {id, status: @getStatus()}

  suggest: (args, word) ->
    @deferredInit()
    @spellchecker.getCorrectionsForMisspelling(word)

  deferredInit: ->
    # If we already have a spellchecker, then we don't have to do anything.
    if @spellchecker
      return

    # Initialize the spell checker which can take some time. We also force
    # the use of the Hunspell library even on Mac OS X. The "system checker"
    # is the one that uses the built-in dictionaries from the operating system.
    checker = new spellchecker.Spellchecker
    checker.setSpellcheckerType spellchecker.ALWAYS_USE_HUNSPELL

    # Build up a list of paths we are checking so we can report them fully
    # to the user if we fail.
    searchPaths = []
    for path in @paths
      searchPaths.push pathspec.getPath(path)

    # Add operating system specific paths to the search list.
    if @checkDefaultPaths
      if env.isLinux()
        searchPaths.push "/usr/share/hunspell"
        searchPaths.push "/usr/share/myspell"
        searchPaths.push "/usr/share/myspell/dicts"

      if env.isDarwin()
        searchPaths.push "/"
        searchPaths.push "/System/Library/Spelling"

      if env.isWindows()
        searchPaths.push "C:\\"

    # Attempt to load all the paths for the dictionary until we find one.
    @log 'checking paths', searchPaths
    for path in searchPaths
      if checker.setDictionary @locale, path
        @log 'found checker', path
        @spellchecker = checker
        return

    # On Windows, if we can't find the dictionary using the paths, then we also
    # try the spelling API. This uses system checker with the given locale, but
    # doesn't provide a path. We do this at the end to let Hunspell be used if
    # the user provides that.
    if env.isWindows()
      systemChecker = new spellchecker.Spellchecker
      systemChecker.setSpellcheckerType spellchecker.ALWAYS_USE_SYSTEM
      if systemChecker.setDictionary @locale, ""
        @log 'using Windows Spell API'
        @spellchecker = systemChecker
        return

    # If all else fails, try the packaged en-US dictionary in the `spellcheck`
    # library.
    if @checkDictionaryPath
      if checker.setDictionary @locale, spellchecker.getDictionaryPath()
        @log 'using packaged locale', path
        @spellchecker = checker
        return

    # If we are using the system checker and we infered the locale, then we
    # don't want to show an error. This is because the system checker may have
    # handled it already.
    if @hasSystemChecker and @inferredLocale
      @log 'giving up quietly because of system checker and inferred locale'
      @enabled = false
      @reason = "Cannot load the locale dictionary for `" + @locale + "`. No warning because system checker is in use and locale is inferred."
      return

    # If we fell through all the if blocks, then we couldn't load the dictionary.
    @enabled = false
    @reason = "Cannot load the locale dictionary for `" + @locale + "`."
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
