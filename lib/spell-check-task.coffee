idCounter = 0

module.exports =
class SpellCheckTask
  @handler: null
  @callbacksById: {}

  constructor: (@task) ->
    @id = idCounter++

  terminate: ->
    delete @constructor.callbacksById[@id]

  start: (buffer) ->
    # Figure out the paths since we need that for checkers that are project-specific.
    projectPath = null
    relativePath = null
    if buffer?.file?.path
      [projectPath, relativePath] = atom.project.relativizePath(buffer.file.path)

    # Submit the spell check request to the background task.
    args = {
      id: @id,
      projectPath,
      relativePath,
      text: buffer.getText()
    }
    @task?.start args, @constructor.dispatchMisspellings

  onDidSpellCheck: (callback) ->
    @constructor.callbacksById[@id] = callback

  @dispatchMisspellings: (data) =>
    @callbacksById[data.id]?(data.misspellings)
