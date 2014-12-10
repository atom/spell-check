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
    @editorSubscription = atom.workspace.observeTextEditors(addViewToEditor)

  deactivate: ->
    @editorSubscription?.off()

addViewToEditor = (editor) ->
  SpellCheckView ?= require './spell-check-view'
  new SpellCheckView(editor)
