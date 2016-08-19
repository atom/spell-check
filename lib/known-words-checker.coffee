class KnownWordsChecker
  enableAdd: false
  spelling: null
  checker: null

  constructor: (knownWords) ->
    # Set up the spelling manager we'll be using.
    spellingManager = require "spelling-manager"
    @spelling = new spellingManager.TokenSpellingManager
    @checker = new spellingManager.BufferSpellingChecker @spelling

    # Set our known words.
    @setKnownWords knownWords

  deactivate: ->
    return

  getId: -> "spell-check:known-words"
  getName: -> "Known Words"
  getPriority: -> 10
  isEnabled: -> @spelling.sensitive or @spelling.insensitive

  getStatus: -> "Working correctly."
  providesSpelling: (args) -> true
  providesSuggestions: (args) -> true
  providesAdding: (args) -> @enableAdd

  check: (args, text) ->
    ranges = []
    checked = @checker.check text
    for token in checked
      if token.status is 1
        ranges.push {start: token.start, end: token.end}
    {correct: ranges}

  suggest: (args, word) ->
    @spelling.suggest word

  getAddingTargets: (args) ->
    if @enableAdd
      [{sensitive: false, label: "Add to " + @getName()}]
    else
      []

  add: (args, target) ->
    c = atom.config.get 'spell-check.knownWords'
    c.push target.word
    atom.config.set 'spell-check.knownWords', c

  setAddKnownWords: (newValue) ->
    @enableAdd = newValue

  setKnownWords: (knownWords) ->
    # Clear out the old list.
    @spelling.sensitive = {}
    @spelling.insensitive = {}

    # Add the new ones into the list.
    if knownWords
      for ignore in knownWords
        @spelling.add ignore

module.exports = KnownWordsChecker
