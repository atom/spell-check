_ = require 'underscore-plus'
{CompositeDisposable} = require 'atom'
SpellCheckTask = require './spell-check-task'

CorrectionsView = null

module.exports =
class SpellCheckView
  @content: ->
    @div class: 'spell-check'

  constructor: (@editor, @task, @spellCheckModule, @getInstance) ->
    @disposables = new CompositeDisposable
    @initializeMarkerLayer()
    @taskWrapper = new SpellCheckTask @task

    @correctMisspellingCommand = atom.commands.add atom.views.getView(@editor), 'spell-check:correct-misspelling', =>
      if marker = @markerLayer.findMarkers({containsBufferPosition: @editor.getCursorBufferPosition()})[0]
        CorrectionsView ?= require './corrections-view'
        @correctionsView?.destroy()
        @correctionsView = new CorrectionsView(@editor, @getCorrections(marker), marker, this, @updateMisspellings)

    atom.views.getView(@editor).addEventListener 'contextmenu', @addContextMenuEntries

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
    @clearContextMenuEntries()

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

  addContextMenuEntries: (mouseEvent) =>
    @clearContextMenuEntries()
    # Get buffer position of the right click event. If the click happens outside
    # the boundaries of any text, the method defaults to the buffer position of the cursor.
    currentScreenPosition = atom.views.getView(@editor).component.screenPositionForMouseEvent mouseEvent
    currentBufferPosition = @editor.bufferPositionForScreenPosition(currentScreenPosition)

    # Check to see if the selected word is incorrect.
    if marker = @markerLayer.findMarkers({containsBufferPosition: currentBufferPosition})[0]
      separatorMenuItem = atom.contextMenu.add {'atom-text-editor': [{type: 'separator'}]}
      @spellCheckModule.contextMenuEntries.push {menuItem: separatorMenuItem}

      corrections = @getCorrections(marker)
      if corrections.length is 0
        @spellCheckModule.contextMenuEntries.push atom.contextMenu.add {'atom-text-editor': [{label: 'No corrections '}]}
      else
        for correction in @getCorrections(marker)
          contextMenuEntry = {}
          # Register new command for correction.
          contextMenuEntry.command = do (correction, contextMenuEntry) =>
            atom.commands.add atom.views.getView(@editor),
              'spell-check:correct-misspelling-' + correction.index, =>
                @makeCorrection(correction, marker)
                @clearContextMenuEntries()

          # Add new menu item for correction.
          contextMenuEntry.menuItem = atom.contextMenu.add {
            'atom-text-editor': [{
              label: correction.label,
              command: 'spell-check:correct-misspelling-' + correction.index
            }]
          }
          @spellCheckModule.contextMenuEntries.push contextMenuEntry

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
  
  clearContextMenuEntries: ->
    for entry in @spellCheckModule.contextMenuEntries
      entry.command?.dispose()
      entry.menuItem?.dispose()

    @spellCheckModule.contextMenuEntries = []

