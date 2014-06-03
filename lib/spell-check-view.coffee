_ = require 'underscore-plus'
{View} = require 'atom'
MisspellingView = require './misspelling-view'
SpellCheckTask = require './spell-check-task'

module.exports =
class SpellCheckView extends View
  @content: ->
    @div class: 'spell-check'

  initialize: (@editorView) ->
    @views = []
    @task = new SpellCheckTask()

    @subscribe @editorView.getEditor(), 'path-changed grammar-changed', =>
      @subscribeToBuffer()

    @subscribe atom.config.observe 'editor.fontSize', callNow: false, =>
      @subscribeToBuffer()
    @subscribe atom.config.observe 'spell-check.grammars', callNow: false, =>
      @subscribeToBuffer()

    @subscribeToBuffer()

  beforeRemove: ->
    @unsubscribeFromBuffer()
    @task.terminate()

  unsubscribeFromBuffer: ->
    @destroyViews()

    if @buffer?
      @unsubscribe(@buffer)
      @buffer = null

  subscribeToBuffer: ->
    @unsubscribeFromBuffer()

    if @spellCheckCurrentGrammar()
      @buffer = @editorView.getEditor().getBuffer()
      @subscribe @buffer, 'contents-modified', =>
        @updateMisspellings()
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

  updateMisspellings: ->
    @task.start @buffer.getText(), (misspellings) =>
      @destroyViews()
      @addViews(misspellings) if @buffer?
