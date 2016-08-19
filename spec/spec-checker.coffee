class SpecChecker
  spelling: null
  checker: null

  constructor: (@id, @isNegative, knownWords) ->
    # Set up the spelling manager we'll be using.
    spellingManager = require "spelling-manager"
    @spelling = new spellingManager.TokenSpellingManager
    @checker = new spellingManager.BufferSpellingChecker @spelling

    # Set our known words.
    @setKnownWords knownWords

  deactivate: ->
    return

  getId: -> "spell-check:spec:" + @id
  getName: -> "Spec Checker"
  getPriority: -> 10
  isEnabled: -> true
  getStatus: -> "Working correctly."
  providesSpelling: (args) -> true
  providesSuggestions: (args) -> false
  providesAdding: (args) -> false

  check: (args, text) ->
    ranges = []
    checked = @checker.check text
    for token in checked
      if token.status is 1
        ranges.push {start: token.start, end: token.end}

    if @isNegative
      {incorrect: ranges}
    else
      {correct: ranges}

  setKnownWords: (knownWords) ->
    # Clear out the old list.
    @spelling.sensitive = {}
    @spelling.insensitive = {}

    # Add the new ones into the list.
    if knownWords
      for ignore in knownWords
        @spelling.add ignore

module.exports = SpecChecker
