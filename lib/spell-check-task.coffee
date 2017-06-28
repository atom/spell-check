idCounter = 0

module.exports =
class SpellCheckTask
  @handler: null
  @jobs: []

  constructor: (@task) ->
    @id = idCounter++

  terminate: ->
    @constructor.removeFromArray(@constructor.jobs, (j) -> j.args.id is @id)

  start: (buffer, onDidSpellCheck) ->
    # Figure out the paths since we need that for checkers that are project-specific.
    projectPath = null
    relativePath = null
    if buffer?.file?.path
      [projectPath, relativePath] = atom.project.relativizePath(buffer.file.path)

    # Remove old jobs for this SpellCheckTask from the shared jobs list.
    @constructor.removeFromArray(@constructor.jobs, (j) -> j.args.id is @id)

    # Create an job that contains everything we'll need to do the work.
    job = {
      task: @task,
      callbacks: [onDidSpellCheck],
      args: {
        id: @id,
        projectPath,
        relativePath,
        text: buffer.getText()
      }
    }

    if (@constructor.jobs.length > 0)
      for i in [0..@constructor.jobs.length-1]
        if (@isDuplicateRequest(@constructor.jobs[i], job))
          console.log('De-duping ' + relativePath)
          @constructor.jobs[i].callbacks.push(onDidSpellCheck)
          return

    # Do the work now if not busy or queue it for later.
    @constructor.jobs.unshift(job)
    if @constructor.jobs.length is 1
      @constructor.startNextJob()
    else
      console.log('Queuing work ' + job.args.id)

  isDuplicateRequest: (a, b) ->
    a.args.projectPath is b.args.projectPath and a.args.relativePath is b.args.relativePath

  @removeFromArray: (array, predicate) ->
    if (array.length > 0)
      for i in [0..array.length-1]
        if (predicate(array[i]))
          found = array[i]
          array.splice(i, 1)
          return found

  @startNextJob: () ->
    job = @jobs[0]
    console.log('Starting work ' + job.args.id)
    job.task?.start job.args, @dispatchMisspellings

  @dispatchMisspellings: (data) =>
    console.log('Completed work ' + data.id)
    job = @removeFromArray(@jobs, (j) -> j.args.id is data.id)
    for callback in job.callbacks
      callback(data.misspellings)

    if @jobs.length > 0
      @startNextJob()
    else
      console.log('Queue is empty')
