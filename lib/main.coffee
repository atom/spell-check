SpellCheckView = null

module.exports =
  config:
    grammars:
      type: 'array'
      default: [
        'source.asciidoc'
        'source.gfm'
        'text.git-commit'
        'text.plain'
        'text.plain.null-grammar'
      ]
      description: 'List of scopes for languages which will be checked for misspellings. See [the README](https://github.com/atom/spell-check#spell-check-package-) for more information on finding the correct scope for a specific language.'

  activate: ->
    @disposable = atom.workspace.observeTextEditors(addViewToEditor)

  deactivate: ->
    @disposable.dispose()

addViewToEditor = (editor) ->
  SpellCheckView ?= require './spell-check-view'
  new SpellCheckView(editor)
