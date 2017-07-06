class SpellCheckerManager
  checkers: []
  checkerPaths: []
  locales: []
  localePaths: []
  useLocales: false
  localeCheckers: null
  knownWords: []
  addKnownWords: false
  knownWordsChecker: null

  setGlobalArgs: (data) ->
    # We need underscore to do the array comparisons.
    _ = require "underscore-plus"

    # Check to see if any values have changed. When they have, they clear out
    # the applicable checker which forces a reload.
    removeLocaleCheckers = false
    removeKnownWordsChecker = false

    if not _.isEqual(@locales, data.locales)
      # If the locales is blank, then we always create a default one. However,
      # any new data.locales will remain blank.
      if not @localeCheckers or data.locales?.length isnt 0
        @locales = data.locales
        removeLocaleCheckers = true
    if not _.isEqual(@localePaths, data.localePaths)
      @localePaths = data.localePaths
      removeLocaleCheckers = true
    if @useLocales isnt data.useLocales
      @useLocales = data.useLocales
      removeLocaleCheckers = true
    if not _.isEqual(@knownWords, data.knownWords)
      @knownWords = data.knownWords
      removeKnownWordsChecker = true
    if @addKnownWords isnt data.addKnownWords
      @addKnownWords = data.addKnownWords
      removeKnownWordsChecker = true

    # If we made a change to the checkers, we need to remove them from the
    # system so they can be reinitialized.
    if removeLocaleCheckers and @localeCheckers
      checkers = @localeCheckers
      for checker in checkers
        @removeSpellChecker checker
      @localeCheckers = null

    if removeKnownWordsChecker and @knownWordsChecker
      @removeSpellChecker @knownWordsChecker
      @knownWordsChecker = null

  addCheckerPath: (checkerPath) ->
    checker = require checkerPath
    @addPluginChecker checker

  addPluginChecker: (checker) ->
    # Add the spell checker to the list.
    @addSpellChecker checker

  addSpellChecker: (checker) ->
    @checkers.push checker

  removeSpellChecker: (spellChecker) ->
    @checkers = @checkers.filter (plugin) -> plugin isnt spellChecker

  check: (args, text) ->
    # Make sure our deferred initialization is done.
    @init()

    # We need a couple packages.
    multirange = require 'multi-integer-range'

    # For every registered spellchecker, we need to find out the ranges in the
    # text that the checker confirms are correct or indicates is a misspelling.
    # We keep these as separate lists since the different checkers may indicate
    # the same range for either and we need to be able to remove confirmed words
    # from the misspelled ones.
    correct = new multirange.MultiRange([])
    incorrects = []

    promises = []
    for checker in @checkers
      # We only care if this plugin contributes to checking spelling.
      if not checker.isEnabled() or not checker.providesSpelling(args)
        continue

      # Get the possibly asynchronous results which include positive
      # (correct) and negative (incorrect) ranges. If we have an incorrect
      # range but no correct, everything not in incorrect is considered correct.
      promises.push Promise.resolve checker.check(args, text)

    Promise.all(promises).then (allResults) =>
      for results in allResults
        if results.invertIncorrectAsCorrect and results.incorrect
          # We need to add the opposite of the incorrect as correct elements in
          # the list. We do this by creating a subtraction.
          invertedCorrect = new multirange.MultiRange([[0, text.length]])
          removeRange = new multirange.MultiRange([])
          for range in results.incorrect
            removeRange.appendRange(range.start, range.end)
          invertedCorrect.subtract(removeRange)

          # Everything in `invertedCorrect` is correct, so add it directly to
          # the list.
          correct.append invertedCorrect
        else if results.correct
          for range in results.correct
            correct.appendRange(range.start, range.end)

        if results.incorrect
          newIncorrect = new multirange.MultiRange([])
          incorrects.push(newIncorrect)

          for range in results.incorrect
            newIncorrect.appendRange(range.start, range.end)

      # If we don't have any incorrect spellings, then there is nothing to worry
      # about, so just return and stop processing.
      if incorrects.length is 0
        return {misspellings: []}

      # Build up an intersection of all the incorrect ranges. We only treat a word
      # as being incorrect if *every* checker that provides negative values treats
      # it as incorrect. We know there are at least one item in this list, so pull
      # that out. If that is the only one, we don't have to do any additional work,
      # otherwise we compare every other one against it, removing any elements
      # that aren't an intersection which (hopefully) will produce a smaller list
      # with each iteration.
      intersection = null

      for incorrect in incorrects
        if intersection is null
          intersection = incorrect
        else
          intersection.append(incorrect)

      # If we have no intersection, then nothing to report as a problem.
      if intersection.length is 0
        return {misspellings: []}

      # Remove all of the confirmed correct words from the resulting incorrect
      # list. This allows us to have correct-only providers as opposed to only
      # incorrect providers.
      if correct.ranges.length > 0
        intersection.subtract(correct)

      # Convert the text ranges (index into the string) into Atom buffer
      # coordinates ( row and column).
      row = 0
      rangeIndex = 0
      lineBeginIndex = 0
      misspellings = []
      while lineBeginIndex < text.length and rangeIndex < intersection.ranges.length
        # Figure out where the next line break is. If we hit -1, then we make sure
        # it is a higher number so our < comparisons work properly.
        lineEndIndex = text.indexOf('\n', lineBeginIndex)
        if lineEndIndex is -1
          lineEndIndex = Infinity

        # Loop through and get all the ranegs for this line.
        loop
          range = intersection.ranges[rangeIndex]
          if range and range[0] < lineEndIndex
            # Figure out the character range of this line. We need this because
            # @addMisspellings doesn't handle jumping across lines easily and the
            # use of the number ranges is inclusive.
            lineRange = new multirange.MultiRange([]).appendRange(lineBeginIndex, lineEndIndex)
            rangeRange = new multirange.MultiRange([]).appendRange(range[0], range[1])
            lineRange.intersect(rangeRange)

            # The range we have here includes whitespace between two concurrent
            # tokens ("zz zz zz" shows up as a single misspelling). The original
            # version would split the example into three separate ones, so we
            # do the same thing, but only for the ranges within the line.
            @addMisspellings(misspellings, row, lineRange.ranges[0], lineBeginIndex, text)

            # If this line is beyond the limits of our current range, we move to
            # the next one, otherwise we loop again to reuse this range against
            # the next line.
            if lineEndIndex >= range[1]
              rangeIndex++
            else
              break
          else
            break

        lineBeginIndex = lineEndIndex + 1
        row++

      # Return the resulting misspellings.
      {misspellings}

  suggest: (args, word) ->
    # Make sure our deferred initialization is done.
    @init()

    # Gather up a list of corrections and put them into a custom object that has
    # the priority of the plugin, the index in the results, and the word itself.
    # We use this to intersperse the results together to avoid having the
    # preferred answer for the second plugin below the least preferred of the
    # first.
    suggestions = []

    for checker in @checkers
      # We only care if this plugin contributes to checking to suggestions.
      if not checker.isEnabled() or not checker.providesSuggestions(args)
        continue

      # Get the suggestions for this word.
      index = 0
      priority = checker.getPriority()

      for suggestion in checker.suggest(args, word)
        suggestions.push {isSuggestion: true, priority: priority, index: index++, suggestion: suggestion, label: suggestion}

    # Once we have the suggestions, then sort them to intersperse the results.
    keys = Object.keys(suggestions).sort (key1, key2) ->
      value1 = suggestions[key1]
      value2 = suggestions[key2]
      weight1 = value1.priority + value1.index
      weight2 = value2.priority + value2.index

      if weight1 isnt weight2
        return weight1 - weight2

      return value1.suggestion.localeCompare(value2.suggestion)

    # Go through the keys and build the final list of suggestions. As we go
    # through, we also want to remove duplicates.
    results = []
    seen = []
    for key in keys
      s = suggestions[key]
      if seen.hasOwnProperty s.suggestion
        continue
      results.push s
      seen[s.suggestion] = 1

    # We also grab the "add to dictionary" listings.
    that = this
    keys = Object.keys(@checkers).sort (key1, key2) ->
      value1 = that.checkers[key1]
      value2 = that.checkers[key2]
      value1.getPriority() - value2.getPriority()

    for key in keys
      # We only care if this plugin contributes to checking to suggestions.
      checker = @checkers[key]
      if not checker.isEnabled() or not checker.providesAdding(args)
        continue

      # Add all the targets to the list.
      targets = checker.getAddingTargets args
      for target in targets
        target.plugin = checker
        target.word = word
        target.isSuggestion = false
        results.push target

    # Return the resulting list of options.
    results

  addMisspellings: (misspellings, row, range, lineBeginIndex, text) ->
    # Get the substring of text, if there is no space, then we can just return
    # the entire result.
    substring = text.substring(range[0], range[1])

    if /\s+/.test substring
      # We have a space, to break it into individual components and push each
      # one to the misspelling list.
      parts = substring.split /(\s+)/
      substringIndex = 0
      for part in parts
        if not /\s+/.test part
          markBeginIndex = range[0] - lineBeginIndex + substringIndex
          markEndIndex = markBeginIndex + part.length
          misspellings.push([[row, markBeginIndex], [row, markEndIndex]])

        substringIndex += part.length

      return

    # There were no spaces, so just return the entire list.
    misspellings.push([
      [row, range[0] - lineBeginIndex],
      [row, range[1] - lineBeginIndex]
    ])

  init: ->
    # See if we need to initialize the system checkers.
    if @localeCheckers is null
      # Initialize the collection. If we aren't using any, then stop doing anything.
      @localeCheckers = []

      if @useLocales
        # If we have a blank location, use the default based on the process. If
        # set, then it will be the best language.
        if not @locales.length
          defaultLocale = process.env.LANG
          if defaultLocale
            @locales = [defaultLocale.split('.')[0]]

        # If we can't figure out the language from the process, check the
        # browser. After testing this, we found that this does not reliably
        # produce a proper IEFT tag for languages; on OS X, it was providing
        # "English" which doesn't work with the locale selection. To avoid using
        # it, we use some tests to make sure it "looks like" an IEFT tag.
        if not @locales.length
          defaultLocale = navigator.language
          if defaultLocale and defaultLocale.length is 5
            separatorChar = defaultLocale.charAt(2)
            if separatorChar is '_' or separatorChar is '-'
              @locales = [defaultLocale]

        # If we still can't figure it out, use US English. It isn't a great
        # choice, but it is a reasonable default not to mention is can be used
        # with the fallback path of the `spellchecker` package.
        if not @locales.length
          @locales = ['en_US']

        # Go through the new list and create new locale checkers.
        SystemChecker = require "./system-checker"
        for locale in @locales
          checker = new SystemChecker locale, @localePaths
          @addSpellChecker checker
          @localeCheckers.push checker

    # See if we need to reload the known words.
    if @knownWordsChecker is null
      KnownWordsChecker = require './known-words-checker'
      @knownWordsChecker = new KnownWordsChecker @knownWords
      @knownWordsChecker.enableAdd = @addKnownWords
      @addSpellChecker @knownWordsChecker

  deactivate: ->
    @checkers = []
    @locales = []
    @localePaths = []
    @useLocales=  false
    @localeCheckers = null
    @knownWords = []
    @addKnownWords = false
    @knownWordsChecker = null

  reloadLocales: ->
    if @localeCheckers
      for localeChecker in @localeCheckers
        @removeSpellChecker localeChecker
      @localeCheckers = null

  reloadKnownWords: ->
    if @knownWordsChecker
      @removeSpellChecker @knownWordsChecker
      @knownWordsChecker = null

manager = new SpellCheckerManager
module.exports = manager
