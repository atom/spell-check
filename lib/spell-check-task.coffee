{Task} = require 'atom'
idCounter = 0

# Wraps a single {Task} so that multiple views reuse the same task but it is
# terminated once all views are removed.
module.exports =
class SpellCheckTask
  @callbacksById: {}

  constructor: ->
    @id = idCounter++

  terminate: ->
    delete @constructor.callbacksById[@id]

    if Object.keys(@constructor.callbacksById).length is 0
      @constructor.task?.terminate()
      @constructor.task = null

  start: (text) ->
    dict = atom.config.get('spell-check.dictionary')
    @constructor.task ?= new Task(require.resolve('./spell-check-handler'))
    @constructor.task?.start {@id, text, dict}, @constructor.dispatchMisspellings

  onDidSpellCheck: (callback) ->
    @constructor.callbacksById[@id] = callback

  @dispatchMisspellings: ({id, misspellings}) =>
    @callbacksById[id]?(misspellings)
