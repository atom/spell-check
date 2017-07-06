idCounter = 0

module.exports =
class SpellCheckTask
  @handler: null
  @jobs: []

  constructor: (@manager) ->
    @id = idCounter++

  terminate: ->
    @constructor.removeFromArray(@constructor.jobs, (j) -> j.args.id is @id)

  start: (editor, onDidSpellCheck) ->
    # Figure out the paths since we need that for checkers that are project-specific.
    buffer = editor.getBuffer()
    projectPath = null
    relativePath = null
    if buffer?.file?.path
      [projectPath, relativePath] = atom.project.relativizePath(buffer.file.path)

    # Remove old jobs for this SpellCheckTask from the shared jobs list.
    @constructor.removeFromArray(@constructor.jobs, (j) -> j.args.id is @id)

    # Create an job that contains everything we'll need to do the work.
    job =
      manager: @manager
      callbacks: [onDidSpellCheck]
      editorId: editor.id
      args:
        id: @id
        projectPath: projectPath
        relativePath: relativePath
        text: buffer.getText()

    # If we already have a job for this work piggy-back on it with our callback.
    return if @constructor.piggybackExistingJob(job)

    # Do the work now if not busy or queue it for later.
    @constructor.jobs.unshift(job)
    @constructor.startNextJob() if @constructor.jobs.length is 1

  @piggybackExistingJob: (newJob) ->
    if @jobs.length > 0
      for job in @jobs
        if @isDuplicateRequest(job, newJob)
          job.callbacks = job.callbacks.concat(newJob.callbacks)
          return true
    return false

  @isDuplicateRequest: (a, b) ->
    a.args.projectPath is b.args.projectPath and a.args.relativePath is b.args.relativePath

  @removeFromArray: (array, predicate) ->
    if (array.length > 0)
      for i in [0..array.length-1]
        if (predicate(array[i]))
          found = array[i]
          array.splice(i, 1)
          return found

  @startNextJob: ->
    activeEditorId = atom.workspace.getActiveTextEditor()?.id
    job = @jobs.find((j) -> j.editorId is activeEditorId) or @jobs[0]

    job.manager.check(job.args, job.args.text).then (results) =>
      @removeFromArray(@jobs, (j) -> j.args.id is job.args.id)
      callback(results.misspellings) for callback in job.callbacks

      @startNextJob() if @jobs.length > 0

  @clear: ->
    @jobs = []
