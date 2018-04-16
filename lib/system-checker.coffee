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

    # Build up a list of paths we are checking so we can report them fully
    # to the user if we fail.
    searchPaths = []

    # Windows uses its own API and the paths are unimportant, only attempting
    # to load it works.
    if /win32/.test process.platform
      searchPaths.push "C:\\"

    # Check the paths supplied by the user.
    for path in @paths
      searchPaths.push path

    # For Linux, we have to search the directory paths to find the dictionary.
    if /linux/.test process.platform
      searchPaths.push "/usr/share/hunspell"
      searchPaths.push "/usr/share/myspell"
      searchPaths.push "/usr/share/myspell/dicts"

    # OS X uses the following paths.
    if /darwin/.test process.platform
      searchPaths.push "/"
      searchPaths.push "/System/Library/Spelling"

    # Try the packaged library inside the node_modules. `getDictionaryPath` is
    # not available, so we have to fake it. This will only work for en-US.
    searchPaths.push spellchecker.getDictionaryPath()

    # Attempt to load all the paths for the dictionary until we find one.
    for path in searchPaths
      if @spellchecker.setDictionary @locale, path
        return

    # If we fell through all the if blocks, then we couldn't load the dictionary.
    @enabled = false
    @reason = "Cannot load the system dictionary for `" + @locale + "`."
    message = @reason \
      + " Checked the following paths for dictionary files:\n* " \
      + searchPaths.join("\n* ")
    noticesMode = atom.config.get('spell-check.noticesMode')

    if noticesMode is "console" or noticesMode is "both"
      console.log @getId(), message
    if noticesMode is "popup" or noticesMode is "both"
      atom.notifications.addError message

module.exports = SystemChecker
