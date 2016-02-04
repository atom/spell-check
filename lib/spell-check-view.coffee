_ = require 'underscore-plus'
{CompositeDisposable} = require 'atom'
SpellCheckTask = require './spell-check-task'

CorrectionsView = null
SpellChecker = null

module.exports =
class SpellCheckView
  @content: ->
    @div class: 'spell-check'

  constructor: (@editor) ->
    @disposables = new CompositeDisposable
    @task = new SpellCheckTask()
    @initializeMarkerLayer()

    @correctMisspellingCommand = atom.commands.add atom.views.getView(@editor), 'spell-check:correct-misspelling', =>
      if marker = @markerLayer.findMarkers({containsPoint: @editor.getCursorBufferPosition()})[0]
        CorrectionsView ?= require './corrections-view'
        @correctionsView?.destroy()
        @correctionsView = new CorrectionsView(@editor, @getCorrections(marker), marker)

    @disposables.add @editor.onDidChangePath =>
      @subscribeToBuffer()

    @disposables.add @editor.onDidChangeGrammar =>
      @subscribeToBuffer()

    @disposables.add atom.config.onDidChange 'editor.fontSize', =>
      @subscribeToBuffer()

    @disposables.add atom.config.onDidChange 'spell-check.grammars', =>
      @subscribeToBuffer()

    @disposables.add atom.config.onDidChange 'spell-check.dictionaryDir', =>
      @subscribeToBuffer()

    @disposables.add atom.config.onDidChange 'spell-check.language', =>
      @subscribeToBuffer()

    @subscribeToBuffer()

    @disposables.add @editor.onDidDestroy(@destroy.bind(this))

  initializeMarkerLayer: ->
    @markerLayer = @editor.getBuffer().addMarkerLayer()
    @markerLayerDecoration = @editor.decorateMarkerLayer(@markerLayer, {
      type: 'highlight',
      class: 'spell-check-misspelling',
      deprecatedRegionClass: 'misspelling'
    })

  destroy: ->
    @unsubscribeFromBuffer()
    @disposables.dispose()
    @task.terminate()
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
      @markerLayer.markRange(misspelling,
        invalidate: 'touch',
        replicate: 'false',
        persistent: false,
        maintainHistory: false,
      )

  showMarkers: (misspellings) =>
    @destroyMarkers()
    @addMarkers(misspellings) if @buffer?

  updateMisspellings: ->
    language = atom.config.get('spell-check.language')
    dictionaryDir = atom.config.get('spell-check.dictionaryDir')
    # Task::start can throw errors atom/atom#3326
    try
      @task.start(@buffer.getText(), @showMarkers, language, dictionaryDir)
    catch error
      console.warn('Error starting spell check task', error.stack ? error)

  getCorrections: (marker) ->
    SpellChecker ?= require 'spellchecker'
    misspelling = @editor.getTextInBufferRange(marker.getRange())
    corrections = SpellChecker.getCorrectionsForMisspelling(misspelling)
