SpellCheckView = null

module.exports =
  configDefaults:
    grammars: [
      'text.plain'
      'source.gfm'
      'text.git-commit'
    ]

  createView: (editorView) ->
    SpellCheckView ?= require './spell-check-view'
    new SpellCheckView(editorView)

  activate: ->
    atom.workspaceView.eachEditorView (editorView) =>
      if editorView.attached and editorView.getPane()?
        editorView.underlayer.append(@createView(editorView))
