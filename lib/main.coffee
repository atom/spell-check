SpellCheckView = null
spellCheckViews = {}

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
    dictionaryDir:
      type: 'string'
      default: '/usr/share/hunspell'
      description: 'Directory containing dictionaries. Has effect only when hunspell is used.'
    language:
      type: 'string'
      default: 'en_US'
      description: 'Language used for spellchecking. Has effect only when hunspell is used.'

  activate: ->
    @commandSubscription = atom.commands.add 'atom-workspace',
        'spell-check:toggle': => @toggle()
    @viewsByEditor = new WeakMap
    @disposable = atom.workspace.observeTextEditors (editor) =>
      SpellCheckView ?= require './spell-check-view'
      spellCheckView = new SpellCheckView(editor)

      # save the {editor} into a map
      editorId = editor.id
      spellCheckViews[editorId] = {}
      spellCheckViews[editorId]['view'] = spellCheckView
      spellCheckViews[editorId]['active'] = true
      @viewsByEditor.set(editor, spellCheckView)

  misspellingMarkersForEditor: (editor) ->
    @viewsByEditor.get(editor).markerLayer.getMarkers()

  deactivate: ->
    @commandSubscription.dispose()
    @commandSubscription = null
    @disposable.dispose()

  # Internal: Toggles the spell-check activation state.
  toggle: ->
    editorId = atom.workspace.getActiveTextEditor().id

    if spellCheckViews[editorId]['active']
      # deactivate spell check for this {editor}
      spellCheckViews[editorId]['active'] = false
      spellCheckViews[editorId]['view'].unsubscribeFromBuffer()
    else
      # activate spell check for this {editor}
      spellCheckViews[editorId]['active'] = true
      spellCheckViews[editorId]['view'].subscribeToBuffer()
