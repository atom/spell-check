SpellCheckView = null

module.exports =
  configDefaults:
    grammars: [
      'source.gfm'
      'text.git-commit'
      'text.plain'
    ]

  activate: ->
    @editorSubscription = atom.workspaceView.eachEditorView(addViewToEditor)

  deactivate: ->
    @editorSubscription?.off()

addViewToEditor = (editorView) ->
  if editorView.attached and editorView.getPane()?
    SpellCheckView ?= require './spell-check-view'
    editorView.underlayer.append(new SpellCheckView(editorView))
