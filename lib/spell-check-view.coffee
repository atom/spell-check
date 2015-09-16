_ = require 'underscore-plus'
{CompositeDisposable} = require 'atom'
MisspellingView = require './misspelling-view'
SpellCheckTask = require './spell-check-task'

module.exports =
class SpellCheckView
  @content: ->
    @div class: 'spell-check'

  constructor: (@editor) ->
    @disposables = new CompositeDisposable
    @views = []
    @task = new SpellCheckTask()

    @task.onDidSpellCheck (misspellings) =>
      @destroyViews()
      @addViews(misspellings) if @buffer?

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

  destroy: ->
    @unsubscribeFromBuffer()
    @disposables.dispose()
    @task.terminate()

  unsubscribeFromBuffer: ->
    @destroyViews()

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

  destroyViews: ->
    while view = @views.shift()
      view.destroy()

  addViews: (misspellings) ->
    for misspelling in misspellings
      view = new MisspellingView(misspelling, @editor)
      @views.push(view)

  updateMisspellings: ->
    # Task::start can throw errors atom/atom#3326
    try
      @task.start(@buffer.getText())
    catch error
      console.warn('Error starting spell check task', error.stack ? error)
