SpellCheckView = null
spellCheckViews = []

module.exports =
  configDefaults:
    grammars: [
      'source.gfm'
      'text.git-commit'
      'text.plain'
      'text.plain.null-grammar'
    ]

  # Internal: The activation state of the spell-check package.
  active: true

  activate: ->
    atom.workspaceView.command 'spell-check:toggle', => @toggle()
    @createViews()

  deactivate: ->
    @editorSubscription?.off()
    while view = spellCheckViews.shift()
      view.destroy()

  createViews: ->
      @editorSubscription = atom.workspaceView.eachEditorView(addViewToEditor)

  # Internal: Toggles the spell-check activation state.
  toggle: () ->
    if @active
      @active = false
      @deactivate()
    else
      @createViews()
      @active = true

addViewToEditor = (editorView) ->
  if editorView.attached and editorView.getPane()?
    SpellCheckView ?= require './spell-check-view'
    spellCheckView = new SpellCheckView(editorView)
    spellCheckViews.push(spellCheckView)
    editorView.underlayer.append(spellCheckView)
