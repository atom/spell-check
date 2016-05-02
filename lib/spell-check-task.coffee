{Task} = require 'atom'
idCounter = 0

module.exports =
class SpellCheckTask
  @handler: null
  @callbacksById: {}

  constructor: (handler) ->
    @id = idCounter++
    @handler = handler

  terminate: ->
    delete @constructor.callbacksById[@id]

    if Object.keys(@constructor.callbacksById).length is 0
      @constructor.task?.terminate()
      @constructor.task = null

  start: (buffer) ->
    # Figure out the paths since we need that for checkers that are project-specific.
    projectPath = null
    relativePath = null
    if buffer?.file?.path
      [projectPath, relativePath] = atom.project.relativizePath(buffer.file.path)

    # We also need to pull out the spelling manager to we can grab fields from that.
    instance = require('./spell-check-manager')

    # Create an arguments that passes everything over. Since tasks are run in a
    # separate background process, they can't use the initialized values from
    # our instance and buffer. We also can't pass complex items across since
    # they are serialized as JSON.
    args = {
      id: @id,
      projectPath: projectPath,
      relativePath: relativePath,
      locales: instance.locales,
      localePaths: instance.localePaths,
      useLocales: instance.useLocales,
      knownWords: instance.knownWords,
      addKnownWords: instance.addKnownWords
    }
    text = buffer.getText()

    # At the moment, we are having some trouble passing the external plugins
    # over to a Task. So, we do this inline for the time being.
    # # Dispatch the request.
    # handlerFilename = require.resolve './spell-check-handler'
    # @constructor.task ?= new Task handlerFilename
    # @constructor.task?.start {args, text}, @constructor.dispatchMisspellings

    # Call the checking in a blocking manner.
    data = instance.check args, text
    @constructor.dispatchMisspellings data

  onDidSpellCheck: (callback) ->
    @constructor.callbacksById[@id] = callback

  @dispatchMisspellings: (data) =>
    @callbacksById[data.id]?(data.misspellings)
