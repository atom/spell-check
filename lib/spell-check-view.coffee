_ = require 'underscore-plus'
{CompositeDisposable} = require 'atom'
SpellCheckTask = require './spell-check-task'

CorrectionsView = null

module.exports =
class SpellCheckView
  @content: ->
    @div class: 'spell-check'

  constructor: (@editor, @task, @getInstance) ->
    @disposables = new CompositeDisposable
    @initializeMarkerLayer()
    @taskWrapper = new SpellCheckTask @task

    @contextMenuCommands = []
    @contextMenuItems = []
    @initializeContextMenuListeners()

    @correctMisspellingCommand = atom.commands.add atom.views.getView(@editor), 'spell-check:correct-misspelling', =>
      if marker = @markerLayer.findMarkers({containsBufferPosition: @editor.getCursorBufferPosition()})[0]
        CorrectionsView ?= require './corrections-view'
        @correctionsView?.destroy()
        @correctionsView = new CorrectionsView(@editor, @getCorrections(marker), marker, this, @updateMisspellings)

    @taskWrapper.onDidSpellCheck (misspellings) =>
      @destroyMarkers()
      @addMarkers(misspellings) if @buffer?

    @disposables.add @editor.onDidChangePath =>
      @subscribeToBuffer()

    @disposables.add @editor.onDidChangeGrammar =>
      @subscribeToBuffer()

    @disposables.add atom.config.onDidChange 'editor.fontSize', =>
      @subscribeToBuffer()

    @disposables.add atom.config.onDidChange 'spell-check.grammars', =>
      @subscribeToBuffer()

    @subscribeToBuffer()

    @disposables.add @editor.onDidDestroy(@destroy.bind(this))

  initializeMarkerLayer: ->
    @markerLayer = @editor.addMarkerLayer({maintainHistory: false})
    @markerLayerDecoration = @editor.decorateMarkerLayer(@markerLayer, {
      type: 'highlight',
      class: 'spell-check-misspelling',
      deprecatedRegionClass: 'misspelling'
    })

  destroy: ->
    @unsubscribeFromBuffer()
    @disposables.dispose()
    @taskWrapper.terminate()
    @markerLayer.destroy()
    @markerLayerDecoration.destroy()
    @correctMisspellingCommand.dispose()
    @correctionsView?.remove()

  unsubscribeFromBuffer: ->
    @destroyMarkers()

    if @buffer?
      @bufferDisposable.dispose()
      @buffer = null

  subscribeToBuffer: ->
    @unsubscribeFromBuffer()

    if @spellCheckCurrentGrammar()
      @buffer = @editor.getBuffer()
      @bufferDisposable = @buffer.onDidStopChanging => @updateMisspellings()
      @updateMisspellings()

  spellCheckCurrentGrammar: ->
    grammar = @editor.getGrammar().scopeName
    _.contains(atom.config.get('spell-check.grammars'), grammar)

  destroyMarkers: ->
    @markerLayer.destroy()
    @markerLayerDecoration.destroy()
    @initializeMarkerLayer()

  addMarkers: (misspellings) ->
    for misspelling in misspellings
      @markerLayer.markBufferRange(misspelling, {invalidate: 'touch'})

  updateMisspellings: ->
    # Task::start can throw errors atom/atom#3326
    try
      @taskWrapper.start @editor.buffer
    catch error
      console.warn('Error starting spell check task', error.stack ? error)

  getCorrections: (marker) ->
    # Build up the arguments object for this buffer and text.
    projectPath = null
    relativePath = null
    if @buffer?.file?.path
      [projectPath, relativePath] = atom.project.relativizePath(@buffer.file.path)
    args = {
      projectPath: projectPath,
      relativePath: relativePath
    }

    # Get the misspelled word and then request corrections.
    instance = @getInstance()
    misspelling = @editor.getTextInBufferRange marker.getBufferRange()
    instance.suggest args, misspelling

  initializeContextMenuListeners: =>
    atom.views.getView(@editor).addEventListener 'mousedown', @addContextMenuEntries
    # Listen for click events from other editors and clear the context menu entries if
    # this view's editor isn't the active editor.
    atom.document.addEventListener 'mousedown', =>
      if @editor.id isnt atom.workspace.getActiveTextEditor().id
        @clearContextMenuEntries()

  addContextMenuEntries: (mouseEvent) =>
    @clearContextMenuEntries()
    # Check to see if a context menu was opened through a right mouse click.
    if mouseEvent.button is 2
      # Get buffer position of the right click event.
      currentScreenPosition = atom.views.getView(@editor).component.screenPositionForMouseEvent mouseEvent
      currentBufferPosition = @editor.bufferPositionForScreenPosition(currentScreenPosition)

      # Check to see if the selected word is incorrect.
      if marker = @markerLayer.findMarkers({containsBufferPosition: currentBufferPosition})[0]
        @contextMenuItems.push atom.contextMenu.add {'atom-text-editor': [{type: 'separator'}]}

        corrections = @getCorrections(marker)
        if corrections.length is 0
          @contextMenuItems.push atom.contextMenu.add {'atom-text-editor': [{label: 'No corrections '}]}
        else
          for correction in @getCorrections(marker)
            # Register new command for correction.
            do (correction) =>
              @contextMenuCommands.push atom.commands.add atom.views.getView(@editor),
                'spell-check:correct-misspelling-' + correction.index, =>
                  @makeCorrection(correction, marker)
                  @clearContextMenuEntries()
            
            # Add new menu item for correction.
            @contextMenuItems.push atom.contextMenu.add {
              'atom-text-editor': [{
                label: correction.label,
                command: 'spell-check:correct-misspelling-' + correction.index
              }]
            }

  makeCorrection: (correction, marker) =>
    if correction.isSuggestion
      # Update the buffer with the correction.
      @editor.setSelectedBufferRange(marker.getBufferRange())
      @editor.insertText(correction.suggestion)
    else
      # Build up the arguments object for this buffer and text.
      projectPath = null
      relativePath = null
      if @editor.buffer?.file?.path
        [projectPath, relativePath] = atom.project.relativizePath(@editor.buffer.file.path)
      args = {
        id: @id,
        projectPath: projectPath,
        relativePath: relativePath
      }

      # Send the "add" request to the plugin.
      correction.plugin.add args, correction

      # Update the buffer to handle the corrections.
      @updateMisspellings.bind(this)()
  
  clearContextMenuEntries: =>
    for command in @contextMenuCommands
      command.dispose()
    for item in @contextMenuItems
      item.dispose()

    @contextMenuCommands = []
    @contextMenuItems = []

