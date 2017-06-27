idCounter = 0
log = console.log

module.exports =
class SpellCheckTask
  @handler: null
  @queue: []

  constructor: (@task) ->
    @id = idCounter++

  terminate: ->
    delete @constructor.callbacksById[@id]

  start: (buffer, onDidSpellCheck) ->
    # Figure out the paths since we need that for checkers that are project-specific.
    projectPath = null
    relativePath = null
    if buffer?.file?.path
      [projectPath, relativePath] = atom.project.relativizePath(buffer.file.path)

    # Ensure old unstarted work for this SpellCheckTask is removed.
    @constructor.removeFromArray(@constructor.queue, (e) -> e.args.id is @id)

    # Create an entry that contains everything we'll need to do the work.
    entry = {
      task: @task,
      callbacks: [onDidSpellCheck],
      args: {
        id: @id,
        projectPath,
        relativePath,
        text: buffer.getText()
      }
    }

    if (@constructor.queue.length > 0)
      for i in [0..@constructor.queue.length-1]
        if (@isDuplicateRequest(@constructor.queue[i], entry))
          log('De-duping ' + relativePath)
          @constructor.queue[i].callbacks.push(onDidSpellCheck)
          return

    # Do the work now if not busy or queue it for later.
    @constructor.queue.unshift(entry)
    if @constructor.queue.length is 1
      @constructor.startTask()
    else
      log('Queuing work ' + entry.args.id)

  isDuplicateRequest: (a, b) ->
    a.args.projectPath is b.args.projectPath and a.args.relativePath is b.args.relativePath

  @removeFromArray: (array, predicate) ->
    if (array.length > 0)
      for i in [0..array.length-1]
        if (predicate(array[i]))
          found = array[i]
          array.splice(i, 1)
          return found

  @startTask: () ->
    entry = @queue[0]
    log('Starting work ' + entry.args.id)
    entry.task?.start entry.args, @dispatchMisspellings

  @dispatchMisspellings: (data) =>
    log('Completed work ' + data.id)
    entry = @removeFromArray(@queue, (e) -> e.args.id is data.id)
    console.log(entry)
    for callback in entry.callbacks
      callback(data.misspellings)

    if @queue.length > 0
      @startTask()
    else
      log('Queue is empty')
