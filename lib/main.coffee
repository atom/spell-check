SpellCheckView = null
spellCheckViews = {}

module.exports =
  instance: null

  activate: ->
    # Create the unified handler for all spellchecking.
    SpellCheckerManager = require './spell-check-manager.coffee'
    @instance = SpellCheckerManager
    that = this

    # Initialize the spelling manager so it can perform deferred loading.
    @instance.locales = atom.config.get('spell-check.locales')
    @instance.localePaths = atom.config.get('spell-check.localePaths')
    @instance.useLocales = atom.config.get('spell-check.useLocales')

    atom.config.onDidChange 'spell-check.locales', ({newValue, oldValue}) ->
      that.instance.locales = atom.config.get('spell-check.locales')
      that.instance.reloadLocales()
      that.updateViews()
    atom.config.onDidChange 'spell-check.localePaths', ({newValue, oldValue}) ->
      that.instance.localePaths = atom.config.get('spell-check.localePaths')
      that.instance.reloadLocales()
      that.updateViews()
    atom.config.onDidChange 'spell-check.useLocales', ({newValue, oldValue}) ->
      that.instance.useLocales = atom.config.get('spell-check.useLocales')
      that.instance.reloadLocales()
      that.updateViews()

    # Add in the settings for known words checker.
    @instance.knownWords = atom.config.get('spell-check.knownWords')
    @instance.addKnownWords = atom.config.get('spell-check.addKnownWords')

    atom.config.onDidChange 'spell-check.knownWords', ({newValue, oldValue}) ->
      that.instance.knownWords = atom.config.get('spell-check.knownWords')
      that.instance.reloadKnownWords()
      that.updateViews()
    atom.config.onDidChange 'spell-check.addKnownWords', ({newValue, oldValue}) ->
      that.instance.addKnownWords = atom.config.get('spell-check.addKnownWords')
      that.instance.reloadKnownWords()
      that.updateViews()

    # Hook up the UI and processing.
    @commandSubscription = atom.commands.add 'atom-workspace',
        'spell-check:toggle': => @toggle()
    @viewsByEditor = new WeakMap
    @disposable = atom.workspace.observeTextEditors (editor) =>
      SpellCheckView ?= require './spell-check-view'
      spellCheckView = new SpellCheckView(editor, @instance)

      # save the {editor} into a map
      editorId = editor.id
      spellCheckViews[editorId] = {}
      spellCheckViews[editorId]['view'] = spellCheckView
      spellCheckViews[editorId]['active'] = true
      @viewsByEditor.set(editor, spellCheckView)

  deactivate: ->
    @instance.deactivate()
    @instance = null
    @commandSubscription.dispose()
    @commandSubscription = null
    @disposable.dispose()

  consumeSpellCheckers: (plugins) ->
    unless plugins instanceof Array
      plugins = [ plugins ]

    for plugin in plugins
      @instance.addPluginChecker plugin

  misspellingMarkersForEditor: (editor) ->
    @viewsByEditor.get(editor).markerLayer.getMarkers()

  updateViews: ->
    for editorId of spellCheckViews
      view = spellCheckViews[editorId]
      if view['active']
        view['view'].updateMisspellings()

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
