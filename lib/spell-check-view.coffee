{_, Task, View} = require 'atom'
MisspellingView = require './misspelling-view'

module.exports =
class SpellCheckView extends View
  @content: ->
    @div class: 'spell-check'

  @task: null
  @instances: 0

  views: []

  initialize: (@editor) ->
    @constructor.task ?= new Task(require.resolve('./spell-check-handler'))
    @constructor.instances++

    @subscribe @editor, 'editor:path-changed', @subscribeToBuffer
    @subscribe @editor, 'editor:grammar-changed', @subscribeToBuffer
    @observeConfig 'editor.fontSize', @subscribeToBuffer
    @observeConfig 'spell-check.grammars', @subscribeToBuffer

    @subscribeToBuffer()

  beforeRemove: ->
    @unsubscribeFromBuffer()

    @constructor.instances--
    if @constructor.instances is 0
      @constructor.task.terminate()
      @constructor.task = null

  unsubscribeFromBuffer: ->
    @destroyViews()

    if @buffer?
      @buffer.off 'contents-modified', @updateMisspellings
      @buffer = null

  subscribeToBuffer: =>
    @unsubscribeFromBuffer()

    if @spellCheckCurrentGrammar()
      @buffer = @editor.getBuffer()
      @buffer.on 'contents-modified', @updateMisspellings
      @updateMisspellings()

  spellCheckCurrentGrammar: ->
    grammar = @editor.getGrammar().scopeName
    _.contains atom.config.get('spell-check.grammars'), grammar

  destroyViews: ->
    while view = @views.shift()
      view.destroy()

  addViews: (misspellings) ->
    for misspelling in misspellings
      view = new MisspellingView(misspelling, @editor)
      @views.push(view)
      @append(view)

  updateMisspellings: =>
    @constructor.task.start @buffer.getText(), (misspellings) =>
      @destroyViews()
      @addViews(misspellings)
