SpellCheckView = null
spellCheckViews = {}

module.exports =
  configDefaults:
    grammars: [
      'source.gfm'
      'text.git-commit'
      'text.plain'
      'text.plain.null-grammar'
    ]

  activate: ->
    atom.workspaceView.command 'spell-check:toggle', => @toggle()
    @editorSubscription = atom.workspaceView.eachEditorView(addViewToEditor)

  deactivate: ->
    @editorSubscription?.off()

  # Internal: Toggles the spell-check activation state.
  toggle: () ->
    editorId = atom.workspace.getActiveEditor().id

    if spellCheckViews[editorId]['active']
      # deactivate spell check for this {editor}
      spellCheckViews[editorId]['active'] = false
      spellCheckViews[editorId]['view'].unsubscribeFromBuffer()
    else
      # activate spell check for this {editor}
      spellCheckViews[editorId]['active'] = true
      spellCheckViews[editorId]['view'].subscribeToBuffer()

addViewToEditor = (editorView) ->
  if editorView.attached and editorView.getPane()?
    SpellCheckView ?= require './spell-check-view'
    spellCheckView = new SpellCheckView(editorView)

    # safe the {editorView} into a map
    editorId = editorView.getEditor().id
    spellCheckViews[editorId] = {}
    spellCheckViews[editorId]['view'] = spellCheckView
    spellCheckViews[editorId]['active'] = true

    editorView.underlayer.append(spellCheckView)
