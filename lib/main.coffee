{CompositeDisposable} = require 'atom'

SpellCheckView = null
spellCheckViews = {}

module.exports =
  activate: ->
    @subs = new CompositeDisposable

    # Since the spell-checking is done on another process, we gather up all the
    # arguments and pass them into the task. Whenever these change, we'll update
    # the object with the parameters and resend it to the task.
    @globalArgs =
      # These are the settings that are part of the main `spell-check` package.
      locales: atom.config.get('spell-check.locales'),
      localePaths: atom.config.get('spell-check.localePaths'),
      useLocales: atom.config.get('spell-check.useLocales'),
      knownWords: atom.config.get('spell-check.knownWords'),
      addKnownWords: atom.config.get('spell-check.addKnownWords'),

      # Collection of all the absolute paths to checkers which will be
      # `require` on the process side to load the checker. We have to do this
      # because we can't pass the actual objects from the main Atom process to
      # the background safely.
      checkerPaths: []

    manager = @getInstance @globalArgs

    # Hook up changes to the configuration settings.
    @excludedScopeRegexLists = []
    @subs.add atom.config.observe 'spell-check.excludedScopes', (excludedScopes) =>
      @excludedScopeRegexLists = excludedScopes.map (excludedScope) ->
        for className in excludedScope.split(/\s+/)[0].split('.') when className
          new RegExp("\\b#{className}\\b")
      @updateViews()

    @subs.add atom.config.onDidChange 'spell-check.locales', ({newValue, oldValue}) =>
      @globalArgs.locales = newValue
      manager.setGlobalArgs @globalArgs
    @subs.add atom.config.onDidChange 'spell-check.localePaths', ({newValue, oldValue}) =>
      @globalArgs.localePaths = newValue
      manager.setGlobalArgs @globalArgs
    @subs.add atom.config.onDidChange 'spell-check.useLocales', ({newValue, oldValue}) =>
      @globalArgs.useLocales = newValue
      manager.setGlobalArgs @globalArgs
    @subs.add atom.config.onDidChange 'spell-check.knownWords', ({newValue, oldValue}) =>
      @globalArgs.knownWords = newValue
      manager.setGlobalArgs @globalArgs
    @subs.add atom.config.onDidChange 'spell-check.addKnownWords', ({newValue, oldValue}) =>
      @globalArgs.addKnownWords = newValue
      manager.setGlobalArgs @globalArgs

    # Hook up the UI and processing.
    @subs.add atom.commands.add 'atom-workspace',
        'spell-check:toggle': => @toggle()
    @viewsByEditor = new WeakMap
    @contextMenuEntries = []
    @subs.add atom.workspace.observeTextEditors (editor) =>
      return if @viewsByEditor.has(editor)

      # For now, just don't spell check large files.
      return if editor.largeFileMode

      # Defer loading the spell check view if we actually need it. This also
      # avoids slowing down Atom's startup by getting it loaded on demand.
      SpellCheckView ?= require './spell-check-view'

      # The SpellCheckView needs both a handle for the task to handle the
      # background checking and a cached view of the in-process manager for
      # getting corrections. We used a function to a function because scope
      # wasn't working properly.
      # Each view also needs the list of added context menu entries so that
      # they can dispose old corrections which were not created by the current
      # active editor. A reference to this entire module is passed right now
      # because a direct reference to @contextMenuEntries wasn't updating
      # properly between different SpellCheckView's.
      spellCheckView = new SpellCheckView(editor, this, manager)

      # save the {editor} into a map
      editorId = editor.id
      spellCheckViews[editorId] =
        view: spellCheckView
        active: true
        editor: editor

      # Make sure that the view is cleaned up on editor destruction.
      destroySub = editor.onDidDestroy =>
        spellCheckView.destroy()
        delete spellCheckViews[editorId]
        @subs.remove destroySub
      @subs.add destroySub

      @viewsByEditor.set editor, spellCheckView

  deactivate: ->
    @instance?.deactivate()
    @instance = null

    # Clear out the known views.
    for editorId of spellCheckViews
      {view} = spellCheckViews[editorId]
      view.destroy()
    spellCheckViews = {}

    # While we have WeakMap.clear, it isn't a function available in ES6. So, we
    # just replace the WeakMap entirely and let the system release the objects.
    @viewsByEditor = new WeakMap

    # Finish up by disposing everything else associated with the plugin.
    @subs.dispose()

  # Registers any Atom packages that provide our service.
  consumeSpellCheckers: (checkerPaths) ->
    # Normalize it so we always have an array.
    unless checkerPaths instanceof Array
      checkerPaths = [ checkerPaths ]

    # Go through and add any new plugins to the list.
    for checkerPath in checkerPaths
      if checkerPath not in @globalArgs.checkerPaths
        @instance?.addCheckerPath checkerPath
        @globalArgs.checkerPaths.push checkerPath

  misspellingMarkersForEditor: (editor) ->
    @viewsByEditor.get(editor).markerLayer.getMarkers()

  updateViews: ->
    for editorId of spellCheckViews
      view = spellCheckViews[editorId]
      if view['active']
        view['view'].updateMisspellings()

  # Retrieves, creating if required, the single SpellingManager instance.
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
    if not atom.workspace.getActiveTextEditor()
      return
    editorId = atom.workspace.getActiveTextEditor().id

    if spellCheckViews[editorId]['active']
      # deactivate spell check for this {editor}
      spellCheckViews[editorId]['active'] = false
      spellCheckViews[editorId]['view'].unsubscribeFromBuffer()
    else
      # activate spell check for this {editor}
      spellCheckViews[editorId]['active'] = true
      spellCheckViews[editorId]['view'].subscribeToBuffer()
