idCounter = 0
log = console.log

module.exports =
class SpellCheckTask
  @handler: null
  @callbacksById: {}
  @isBusy: false
  @queue: []

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
    entry = {
      task: @task,
      args: {
        id: @id,
        projectPath,
        relativePath,
        text: buffer.getText()
      }
    }

    log('Pushing ' + @id, entry)
    queue = @constructor.queue

    if (queue.length > 0)
      for i in [0..queue.length-1]
        if (queue[i].id is @id)
          log('Ejecting previous entry at ' + i)
          queue.splice(i, 1)
          break

    queue.push(entry)
    @constructor.sendNextMaybe()

  @sendNextMaybe: ->
    if not @isBusy and @queue.length > 0
      @isBusy = true
      entry = @queue.shift()
      log('Dispatching ' + entry.args.id + ' from queue of ' + (@queue.length + 1))
      entry.task?.start entry.args, @dispatchMisspellings

  onDidSpellCheck: (callback) ->
    @constructor.callbacksById[@id] = callback

  @dispatchMisspellings: (data) =>
    log('completed ' + data.id, data)
    @callbacksById[data.id]?(data.misspellings)
    @isBusy = false
    @sendNextMaybe()
