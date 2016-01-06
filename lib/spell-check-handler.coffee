SpellChecker = require 'spellchecker'

wordRegex = /(?:^\')?([A-Z][a-z]+(\'[a-z]+)?|[a-z]+(\'[a-z]+)?|[A-Z]+)/g

module.exports = (text) ->
  row = 0
  misspellings = []
  for line in text.split('\n')
    while matches = wordRegex.exec(line)
      word = matches[1]
      continue if word in ['GitHub', 'github']
      continue unless SpellChecker.isMisspelled(word)

      startColumn = matches.index + matches[0].length - word.length
      endColumn = startColumn + word.length
      misspellings.push([[row, startColumn], [row, endColumn]])
    row++
  misspellings
