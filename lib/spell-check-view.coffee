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

    @task.onDidSpellCheck (misspellings) =>
      @detroyMarkers()
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
    @detroyMarkers()

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

  detroyMarkers: ->
    @markerLayer.destroy()
    @markerLayerDecoration.destroy()
    @initializeMarkerLayer()

  addMarkers: (misspellings) ->
    scope_whitelist = atom.config.get('spell-check.scopes')
    for misspelling in misspellings
      # Find scopes for the text given at the starting position of the misspelling
      scopes_for_misspelling = @editor.scopeDescriptorForBufferPosition(misspelling[0]).getScopesArray()
      # Mark the misspelling if there is no whitelist or there are whole-word matches between
      # the scopes and the whitelist
      if scope_whitelist.length is 0 or _.intersection(scopes_for_misspelling, scope_whitelist).length > 0
        @markerLayer.markRange(misspelling,
          invalidate: 'touch',
          replicate: 'false',
          persistent: false,
          maintainHistory: false,
        )
    return

  updateMisspellings: ->
    # Task::start can throw errors atom/atom#3326
    try
      @task.start(@buffer.getText())
    catch error
      console.warn('Error starting spell check task', error.stack ? error)

  getCorrections: (marker) ->
    SpellChecker ?= require 'spellchecker'
    misspelling = @editor.getTextInBufferRange(marker.getRange())
    corrections = SpellChecker.getCorrectionsForMisspelling(misspelling)
