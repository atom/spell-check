SpellCheckView = null

module.exports =
  config:
    grammars:
      type: 'array'
      default: [
        'source.gfm'
        'text.git-commit'
        'text.plain'
        'text.plain.null-grammar'
      ]

  activate: ->
    @disposable = atom.workspace.observeTextEditors(addViewToEditor)

  deactivate: ->
    @disposable.dispose()

addViewToEditor = (editor) ->
  SpellCheckView ?= require './spell-check-view'
  new SpellCheckView(editor)
