{Task} = require 'atom'

# Wraps a single {Task} so that multiple views reuse the same task but it is
# terminated once all views are removed.
module.exports =
class SpellCheckTask
  @numEditors = 0

  constructor: ->
    @constructor.numEditors++

  terminate: ->
    @constructor.numEditors--;
    if @constructor.numEditors is 0
      @constructor.task?.terminate()
      @constructor.task = null

  start: (text, callback, language, dictionaryDir) ->
    @constructor.task ?= new Task(require.resolve('./spell-check-handler'))
    @constructor.task?.start {text, language, dictionaryDir}, callback
