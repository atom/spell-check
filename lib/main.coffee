{Task} = require 'atom'

SpellCheckView = null
spellCheckViews = {}

module.exports =
  activate: ->
    # Set up the task for handling spell-checking in the background. This is
    # what is actually in the background.
    handlerFilename = require.resolve './spell-check-handler'
    @task ?= new Task handlerFilename

    # Set up our callback to track when settings changed.
    that = this
    @task.on "spell-check:settings-changed", (ignore) ->
      that.updateViews()

    # Since the spell-checking is done on another process, we gather up all the
    # arguments and pass them into the task. Whenever these change, we'll update
    # the object with the parameters and resend it to the task.
    @globalArgs = {
      locales: atom.config.get('spell-check.locales'),
      localePaths: atom.config.get('spell-check.localePaths'),
      useLocales: atom.config.get('spell-check.useLocales'),
      knownWords: atom.config.get('spell-check.knownWords'),
      addKnownWords: atom.config.get('spell-check.addKnownWords'),
      checkerPaths: []
    }
    @sendGlobalArgs()

    atom.config.onDidChange 'spell-check.locales', ({newValue, oldValue}) ->
      that.globalArgs.locales = newValue
      that.sendGlobalArgs()
    atom.config.onDidChange 'spell-check.localePaths', ({newValue, oldValue}) ->
      that.globalArgs.localePaths = newValue
      that.sendGlobalArgs()
    atom.config.onDidChange 'spell-check.useLocales', ({newValue, oldValue}) ->
      that.globalArgs.useLocales = newValue
      that.sendGlobalArgs()
    atom.config.onDidChange 'spell-check.knownWords', ({newValue, oldValue}) ->
      that.globalArgs.knownWords = newValue
      that.sendGlobalArgs()
    atom.config.onDidChange 'spell-check.addKnownWords', ({newValue, oldValue}) ->
      that.globalArgs.addKnownWords = newValue
      that.sendGlobalArgs()

    # Hook up the UI and processing.
    @commandSubscription = atom.commands.add 'atom-workspace',
        'spell-check:toggle': => @toggle()
    @viewsByEditor = new WeakMap
    @disposable = atom.workspace.observeTextEditors (editor) =>
      SpellCheckView ?= require './spell-check-view'

      # The SpellCheckView needs both a handle for the task to handle the
      # background checking and a cached view of the in-process manager for
      # getting corrections. We used a function to a function because scope
      # wasn't working properly.
      spellCheckView = new SpellCheckView(editor, @task, => @getInstance @globalArgs)

      # save the {editor} into a map
      editorId = editor.id
      spellCheckViews[editorId] = {}
      spellCheckViews[editorId]['view'] = spellCheckView
      spellCheckViews[editorId]['active'] = true
      spellCheckViews[editorId]['editor'] = editor
      @viewsByEditor.set editor, spellCheckView

  deactivate: ->
    @instance?.deactivate()
    @instance = null
    @task?.terminate()
    @task = null
    @commandSubscription.dispose()
    @commandSubscription = null

    # Clear out the known views.
    for editorId of spellCheckViews
      view = spellCheckViews[editorId]
      view['editor'].destroy()
    spellCheckViews = {}

    # While we have WeakMap.clear, it isn't a function available in ES6. So, we
    # just replace the WeakMap entirely and let the system release the objects.
    @viewsByEditor = new WeakMap

    # Finish up by disposing everything else associated with the plugin.
    @disposable.dispose()

  # Registers any Atom packages that provide our service. Because we use a Task,
  # we have to load the plugin's checker in both that service and in the Atom
  # process (for coming up with corrections). Since everything passed to the
  # task must be JSON serialized, we pass the full path to the task and let it
  # require it on that end.
  consumeSpellCheckers: (checkerPaths) ->
    # Normalize it so we always have an array.
    unless checkerPaths instanceof Array
      checkerPaths = [ checkerPaths ]

    # Go through and add any new plugins to the list.
    for checkerPath in checkerPaths
      if checkerPath not in @globalArgs.checkerPaths
        @task?.send {type: "checker", checkerPath: checkerPath}
        @instance?.addCheckerPath checkerPath
        @globalArgs.checkerPaths.push checkerPath

  misspellingMarkersForEditor: (editor) ->
    @viewsByEditor.get(editor).markerLayer.getMarkers()

  updateViews: ->
    for editorId of spellCheckViews
      view = spellCheckViews[editorId]
      if view['active']
        view['view'].updateMisspellings()

  sendGlobalArgs: ->
    @task.send {type: "global", global: @globalArgs}

  # Retrieves, creating if required, a spelling manager for use with
  # synchronous operations such as retrieving corrections.
  getInstance: (globalArgs) ->
    if not @instance
      SpellCheckerManager = require './spell-check-manager'
      @instance = SpellCheckerManager
      @instance.setGlobalArgs globalArgs

      for checkerPath in globalArgs.checkerPaths
        @instance.addCheckerPath checkerPath

    return @instance

  # Internal: Toggles the spell-check activation state.
  toggle: ->
    editorId = atom.workspace.getActiveTextEditor().id

    if spellCheckViews[editorId]['active']
      # deactivate spell check for this {editor}
      spellCheckViews[editorId]['active'] = false
      spellCheckViews[editorId]['view'].unsubscribeFromBuffer()
    else
      # activate spell check for this {editor}
      spellCheckViews[editorId]['active'] = true
      spellCheckViews[editorId]['view'].subscribeToBuffer()
