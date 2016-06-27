SpellChecker = require 'spellchecker'

module.exports = ({id, text, dict}) ->
  SpellChecker.add("GitHub")
  SpellChecker.add("github")

  dict.filter((word) ->
    word
  ).forEach (word) ->
    word = word.trim()
    capitalized = word.charAt(0).toUpperCase() + word.slice(1)
    SpellChecker.add(word)
    if word isnt capitalized
      SpellChecker.add(capitalized)

  misspelledCharacterRanges = SpellChecker.checkSpelling(text)

  row = 0
  rangeIndex = 0
  characterIndex = 0
  misspellings = []
  while characterIndex < text.length and rangeIndex < misspelledCharacterRanges.length
    lineBreakIndex = text.indexOf('\n', characterIndex)
    if lineBreakIndex is -1
      lineBreakIndex = Infinity

    loop
      range = misspelledCharacterRanges[rangeIndex]
      if range and range.start < lineBreakIndex
        misspellings.push([
          [row, range.start - characterIndex],
          [row, range.end - characterIndex]
        ])
        rangeIndex++
      else
        break

    characterIndex = lineBreakIndex + 1
    row++

  {id, misspellings}
