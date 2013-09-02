SpellCheckView = null

module.exports =
  configDefaults:
    grammars: [
      'text.plain'
      'source.gfm'
      'text.git-commit'
    ]

  createView: (editor) ->
    SpellCheckView ?= require './spell-check-view'
    new SpellCheckView(editor)

  activate: ->
    rootView.eachEditor (editor) =>
      if editor.attached and editor.getPane()?
        editor.underlayer.append(@createView(editor))
