spellchecker = require 'spellchecker'

class SystemChecker
  spellchecker: null
  locale: null
  enabled: true
  reason: null
  paths: null

  constructor: (locale, paths) ->
    @locale = locale
    @paths = paths

  deactivate: ->
    return

  getId: -> "spell-check:" + @locale.toLowerCase().replace("_", "-")
  getName: -> "System Dictionary (" + @locale + ")"
  getPriority: -> 100 # System level data, has no user input.
  isEnabled: -> @enabled
  getStatus: ->
    if @enabled
      "Working correctly."
    else
      @reason

  providesSpelling: (args) -> true
  providesSuggestions: (args) -> true
  providesAdding: (args) -> false # Users shouldn't be adding to the system dictionary.

  check: (args, text) ->
    @deferredInit()
    @spellchecker.checkSpellingAsync(text).then (incorrect) ->
      {invertIncorrectAsCorrect: true, incorrect}

  suggest: (args, word) ->
    @deferredInit()
    @spellchecker.getCorrectionsForMisspelling(word)

  deferredInit: ->
    # If we already have a spellchecker, then we don't have to do anything.
    if @spellchecker
      return

    # Initialize the spell checker which can take some time.
    @spellchecker = new spellchecker.Spellchecker

    # Windows uses its own API and the paths are unimportant, only attempting
    # to load it works.
    if /win32/.test process.platform
      if @spellchecker.setDictionary @locale, "C:\\"
        return

    # Check the paths supplied by the user.
    for path in @paths
      if @spellchecker.setDictionary @locale, path
        return

    # For Linux, we have to search the directory paths to find the dictionary.
    if /linux/.test process.platform
      if @spellchecker.setDictionary @locale, "/usr/share/hunspell"
        return
      if @spellchecker.setDictionary @locale, "/usr/share/myspell"
        return
      if @spellchecker.setDictionary @locale, "/usr/share/myspell/dicts"
        return

    # OS X uses the following paths.
    if /darwin/.test process.platform
      if @spellchecker.setDictionary @locale, "/"
        return
      if @spellchecker.setDictionary @locale, "/System/Library/Spelling"
        return

    # Try the packaged library inside the node_modules. `getDictionaryPath` is
    # not available, so we have to fake it. This will only work for en-US.
    path = require 'path'
    vendor = path.join __dirname, "..", "node_modules", "spellchecker", "vendor", "hunspell_dictionaries"
    if @spellchecker.setDictionary @locale, vendor
      return

    # If we fell through all the if blocks, then we couldn't load the dictionary.
    @enabled = false
    @reason = "Cannot find dictionary for " + @locale + "."
    console.log @getId(), "Can't load " + @locale + ": " + @reason

module.exports = SystemChecker
