SpellChecker = require 'spellchecker'

wordRegex = /(?:^|[\s\[\]"'])([a-zA-Z]+([a-zA-Z']+[a-zA-Z])?)(?=[\s\.\[\]:,"']|$)/g

module.exports = ({id, range, text}) ->
  row = range.start.row
  first = true
  misspellings = []
  for line in text.split('\n')
    while matches = wordRegex.exec(line)
      word = matches[1]
      continue if word in ['GitHub', 'github']
      continue unless SpellChecker.isMisspelled(word)

      columnOffset = if first then range.start.column else 0
      first = false
      startColumn = columnOffset + matches.index + matches[0].length - word.length
      endColumn = startColumn + word.length
      misspellings.push([[row, startColumn], [row, endColumn]])
    row++
  {id, range, misspellings}
