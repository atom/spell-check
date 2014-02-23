_ = require 'underscore-plus'
{Task, View} = require 'atom'
MisspellingView = require './misspelling-view'

module.exports =
class SpellCheckView extends View
  @content: ->
    @div class: 'spell-check'

  @createTask: ->
    @task ?= new Task(require.resolve('./spell-check-handler'))
    if @activeViews?
      @activeViews++
    else
      @activeViews = 1

  @destroyTask: ->
    @activeViews--
    if @activeViews is 0
      @task?.terminate()
      @task = null

  @startTask: (args...) ->
    @task.start(args...)

  initialize: (@editorView) ->
    @views = []
    @constructor.createTask()

    @subscribe editorView, 'editor:path-changed', @subscribeToBuffer
    @subscribe editorView, 'editor:grammar-changed', @subscribeToBuffer
    @subscribe atom.config.observe 'editor.fontSize', @subscribeToBuffer
    @subscribe atom.config.observe 'spell-check.grammars', @subscribeToBuffer

    @subscribeToBuffer()

  beforeRemove: ->
    @unsubscribeFromBuffer()
    @constructor.destroyTask()

  unsubscribeFromBuffer: ->
    @destroyViews()

    if @buffer?
      @unsubscribe(@buffer)
      @buffer = null

  subscribeToBuffer: =>
    @unsubscribeFromBuffer()

    if @spellCheckCurrentGrammar()
      @buffer = @editorView.getEditor().getBuffer()
      @subscribe @buffer, 'contents-modified', @updateMisspellings
      @updateMisspellings()

  spellCheckCurrentGrammar: ->
    grammar = @editorView.getEditor().getGrammar().scopeName
    _.contains(atom.config.get('spell-check.grammars'), grammar)

  destroyViews: ->
    while view = @views.shift()
      view.destroy()

  addViews: (misspellings) ->
    for misspelling in misspellings
      view = new MisspellingView(misspelling, @editorView)
      @views.push(view)
      @append(view)

  updateMisspellings: =>
    @constructor.startTask @buffer.getText(), (misspellings) =>
      @destroyViews()
      @addViews(misspellings)
