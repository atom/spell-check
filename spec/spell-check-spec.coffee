SpellCheckTask = require '../lib/spell-check-task'

describe "Spell check", ->
  [workspaceElement, editor, editorElement, spellCheckModule] = []

  textForMarker = (marker) ->
    editor.getTextInBufferRange(marker.getBufferRange())

  getMisspellingMarkers = ->
    spellCheckModule.misspellingMarkersForEditor(editor)

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)

    waitsForPromise ->
      atom.packages.activatePackage('language-text')

    waitsForPromise ->
      atom.packages.activatePackage('language-javascript')

    waitsForPromise ->
      atom.workspace.open('sample.js')

    waitsForPromise ->
      atom.packages.activatePackage('spell-check').then ({mainModule}) ->
        spellCheckModule = mainModule

    runs ->
      atom.config.set('spell-check.grammars', [])

    runs ->
      jasmine.attachToDOM(workspaceElement)
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)

  afterEach ->
    SpellCheckTask.clear()

  it "decorates all misspelled words", ->
    atom.config.set('spell-check.locales', ['en-US'])
    editor.setText("This middle of thiss\nsentencts\n\nhas issues and the \"edn\" 'dsoe' too")
    atom.config.set('spell-check.grammars', ['source.js'])

    misspellingMarkers = null
    waitsFor ->
      misspellingMarkers = getMisspellingMarkers()
      if misspellingMarkers.length is 4
        expect(textForMarker(misspellingMarkers[0])).toEqual "thiss"
        expect(textForMarker(misspellingMarkers[1])).toEqual "sentencts"
        expect(textForMarker(misspellingMarkers[2])).toEqual "edn"
        expect(textForMarker(misspellingMarkers[3])).toEqual "dsoe"
        true

  it "decorates misspelled words with a leading space", ->
    atom.config.set('spell-check.locales', ['en-US'])
    editor.setText("\nchok bok")
    atom.config.set('spell-check.grammars', ['source.js'])

    misspellingMarkers = null
    waitsFor ->
      misspellingMarkers = getMisspellingMarkers()
      if misspellingMarkers.length is 2
        expect(textForMarker(misspellingMarkers[0])).toEqual "chok"
        expect(textForMarker(misspellingMarkers[1])).toEqual "bok"
        true

  it "allows certains scopes to be excluded from spell checking", ->
    editor.setText("""
      speledWrong = 5;
      function speledWrong() {}
      class SpeledWrong {}
    """)

    atom.config.set('spell-check.grammars', ['source.js'])
    atom.config.set('spell-check.excludedScopes', ['.function.entity'])

    markers = []
    waitsFor 'initial markers to appear', ->
      markers = getMisspellingMarkers()
      markers.length > 0

    runs ->
      expect(markers.map (marker) -> marker.getBufferRange()).toEqual([
        [[0, 0], [0, 11]],
        [[2, 6], [2, 17]]
      ])

    runs ->
      atom.config.set('spell-check.excludedScopes', ['.functio.entity'])

    waitsFor 'markers to update', ->
      markers = getMisspellingMarkers()
      markers.length is 3

    runs ->
      expect(markers.map (marker) -> marker.getBufferRange()).toEqual([
        [[0, 0], [0, 11]],
        [[1, 9], [1, 20]],
        [[2, 6], [2, 17]]
      ])

    runs ->
      atom.config.set('spell-check.excludedScopes', [
        '.meta.class'
      ])

    waitsFor 'markers to update', ->
      markers = getMisspellingMarkers()
      markers.length is 2

    runs ->
      expect(markers.map (marker) -> marker.getBufferRange()).toEqual([
        [[0, 0], [0, 11]],
        [[1, 9], [1, 20]],
      ])

  it "allow entering of known words", ->
    atom.config.set('spell-check.knownWords', ['GitHub', '!github', 'codez'])
    atom.config.set('spell-check.locales', ['en-US'])
    editor.setText("GitHub (aka github): Where codez are builz.")
    atom.config.set('spell-check.grammars', ['source.js'])

    misspellingMarkers = null
    waitsFor ->
      misspellingMarkers = getMisspellingMarkers()
      if misspellingMarkers.length is 1
        expect(textForMarker(misspellingMarkers[0])).toBe "builz"
        true

  it "hides decorations when a misspelled word is edited", ->
    editor.setText('notaword')
    advanceClock(editor.getBuffer().getStoppedChangingDelay())
    atom.config.set('spell-check.grammars', ['source.js'])

    waitsFor ->
      getMisspellingMarkers().length is 1

    runs ->
      editor.moveToEndOfLine()
      editor.insertText('a')
      advanceClock(editor.getBuffer().getStoppedChangingDelay())

      misspellingMarkers = getMisspellingMarkers()

      expect(misspellingMarkers.length).toBe 1
      expect(misspellingMarkers[0].isValid()).toBe false

  describe "when spell checking for a grammar is removed", ->
    it "removes all the misspellings", ->
      atom.config.set('spell-check.locales', ['en-US'])
      editor.setText('notaword')
      advanceClock(editor.getBuffer().getStoppedChangingDelay())
      atom.config.set('spell-check.grammars', ['source.js'])

      waitsFor ->
        getMisspellingMarkers().length is 1

      runs ->
        atom.config.set('spell-check.grammars', [])
        expect(getMisspellingMarkers().length).toBe 0

  describe "when spell checking for a grammar is toggled off", ->
    it "removes all the misspellings", ->
      atom.config.set('spell-check.locales', ['en-US'])
      editor.setText('notaword')
      advanceClock(editor.getBuffer().getStoppedChangingDelay())
      atom.config.set('spell-check.grammars', ['source.js'])

      waitsFor ->
        getMisspellingMarkers().length is 1

      runs ->
        atom.commands.dispatch(workspaceElement, 'spell-check:toggle')
        expect(getMisspellingMarkers().length).toBe 0

  describe "when the editor's grammar changes to one that does not have spell check enabled", ->
    it "removes all the misspellings", ->
      atom.config.set('spell-check.locales', ['en-US'])
      editor.setText('notaword')
      advanceClock(editor.getBuffer().getStoppedChangingDelay())
      atom.config.set('spell-check.grammars', ['source.js'])

      misspellingMarkers = null
      waitsFor ->
        misspellingMarkers = getMisspellingMarkers()
        misspellingMarkers.length is 1

      runs ->
        editor.setGrammar(atom.grammars.selectGrammar('.txt'))
        expect(getMisspellingMarkers().length).toBe 0

  describe "when 'spell-check:correct-misspelling' is triggered on the editor", ->
    describe "when the cursor touches a misspelling that has corrections", ->
      it "displays the corrections for the misspelling and replaces the misspelling when a correction is selected", ->
        atom.config.set('spell-check.locales', ['en-US'])
        editor.setText('tofether')
        advanceClock(editor.getBuffer().getStoppedChangingDelay())
        atom.config.set('spell-check.grammars', ['source.js'])
        correctionsElement = null

        waitsFor ->
          getMisspellingMarkers().length is 1

        runs ->
          expect(getMisspellingMarkers()[0].isValid()).toBe true

          atom.commands.dispatch editorElement, 'spell-check:correct-misspelling'

          correctionsElement = editorElement.querySelector('.corrections')
          expect(correctionsElement).toBeDefined()
          expect(correctionsElement.querySelectorAll('li').length).toBeGreaterThan 0
          expect(correctionsElement.querySelectorAll('li')[0].textContent).toBe "together"

          atom.commands.dispatch correctionsElement, 'core:confirm'

          expect(editor.getText()).toBe 'together'
          expect(editor.getCursorBufferPosition()).toEqual [0, 8]

          expect(getMisspellingMarkers()[0].isValid()).toBe false
          expect(editorElement.querySelector('.corrections')).toBeNull()

    describe "when the cursor touches a misspelling that has no corrections", ->
      it "displays a message saying no corrections found", ->
        atom.config.set('spell-check.locales', ['en-US'])
        editor.setText('zxcasdfysyadfyasdyfasdfyasdfyasdfyasydfasdf')
        advanceClock(editor.getBuffer().getStoppedChangingDelay())
        atom.config.set('spell-check.grammars', ['source.js'])

        waitsFor ->
          getMisspellingMarkers().length > 0

        runs ->
          atom.commands.dispatch editorElement, 'spell-check:correct-misspelling'
          expect(editorElement.querySelectorAll('.corrections').length).toBe 1
          expect(editorElement.querySelectorAll('.corrections li').length).toBe 0
          expect(editorElement.querySelector('.corrections').textContent).toMatch /No corrections/

  describe "when a right mouse click is triggered on the editor", ->
    describe "when the cursor touches a misspelling that has corrections", ->
      it "displays the context menu items for the misspelling and replaces the misspelling when a correction is selected", ->
        atom.config.set('spell-check.locales', ['en-US'])
        editor.setText('tofether')
        advanceClock(editor.getBuffer().getStoppedChangingDelay())
        atom.config.set('spell-check.grammars', ['source.js'])

        waitsFor ->
          getMisspellingMarkers().length is 1

        runs ->
          expect(getMisspellingMarkers()[0].isValid()).toBe true
          editorElement.dispatchEvent(new MouseEvent('contextmenu'))

          # Check that the proper context menu entries are created for the misspelling.
          # A misspelling will have atleast 2 context menu items for the lines separating
          # the corrections.
          expect(spellCheckModule.contextMenuEntries.length).toBeGreaterThan 2
          commandName = 'spell-check:correct-misspelling-0'
          menuItemLabel = 'together'

          editorCommands = atom.commands.findCommands(target: editorElement)
          correctionCommand = (command for command in editorCommands when command.name is commandName)
          expect(correctionCommand).toBeDefined

          correctionMenuItem = (item for item in atom.contextMenu.itemSets when item.items[0].label is menuItemLabel)[0]
          expect(correctionMenuItem).toBeDefined

          atom.commands.dispatch editorElement, commandName

          # Check that the misspelling is corrected and the context menu entries are properly disposed.
          expect(editor.getText()).toBe 'together'
          expect(editor.getCursorBufferPosition()).toEqual [0, 8]
          expect(getMisspellingMarkers()[0].isValid()).toBe false

          expect(spellCheckModule.contextMenuEntries.length).toBe 0

          editorCommands = atom.commands.findCommands(target: editorElement)
          correctionCommand = (command for command in editorCommands when command.name is commandName)
          expect(correctionCommand).toBeNull

          correctionMenuItem = (item for item in atom.contextMenu.itemSets when item.items[0].label is menuItemLabel)[0]
          expect(correctionMenuItem).toBeNull

    describe "when the cursor touches a misspelling and adding known words is enabled", ->
      it "displays the 'Add to Known Words' option and adds that word when the option is selected", ->
        atom.config.set('spell-check.locales', ['en-US'])
        editor.setText('zxcasdfysyadfyasdyfasdfyasdfyasdfyasydfasdf')
        advanceClock(editor.getBuffer().getStoppedChangingDelay())
        atom.config.set('spell-check.grammars', ['source.js'])
        atom.config.set('spell-check.addKnownWords', true)

        expect(atom.config.get('spell-check.knownWords').length).toBe 0

        waitsFor ->
          getMisspellingMarkers().length is 1

        runs ->
          expect(getMisspellingMarkers()[0].isValid()).toBe true
          editorElement.dispatchEvent(new MouseEvent('contextmenu'))

          # Check that the 'Add to Known Words' entry is added to the context menu.
          # There should be 1 entry for 'Add to Known Words' and 2 entries for the line separators.
          expect(spellCheckModule.contextMenuEntries.length).toBe 3
          commandName = 'spell-check:correct-misspelling-0'
          menuItemLabel = 'together'

          editorCommands = atom.commands.findCommands(target: editorElement)
          correctionCommand = (command for command in editorCommands when command.name is commandName)
          expect(correctionCommand).toBeDefined

          correctionMenuItem = (item for item in atom.contextMenu.itemSets when item.items[0].label is menuItemLabel)[0]
          expect(correctionMenuItem).toBeDefined

          atom.commands.dispatch editorElement, commandName

          # Check that the misspelling is added as a known word, that there are no more misspelling
          # markers in the editor, and that the context menu entries are properly disposed.
          waitsFor ->
            getMisspellingMarkers().length is 0

          runs ->
            expect(atom.config.get('spell-check.knownWords').length).toBe 1
            expect(spellCheckModule.contextMenuEntries.length).toBe 0

            editorCommands = atom.commands.findCommands(target: editorElement)
            correctionCommand = (command for command in editorCommands when command.name is commandName)
            expect(correctionCommand).toBeNull

            correctionMenuItem = (item for item in atom.contextMenu.itemSets when item.items[0].label is menuItemLabel)[0]
            expect(correctionMenuItem).toBeNull

  describe "when the editor is destroyed", ->
    it "destroys all misspelling markers", ->
      atom.config.set('spell-check.locales', ['en-US'])
      editor.setText('mispelling')
      atom.config.set('spell-check.grammars', ['source.js'])

      waitsFor ->
        getMisspellingMarkers().length > 0

      runs ->
        editor.destroy()
        expect(getMisspellingMarkers().length).toBe 0
        # Check that all the views have been cleaned up.
        expect(spellCheckModule.updateViews().length).toBe 0

  describe "when using checker plugins", ->
    it "no opinion on input means correctly spells", ->
      spellCheckModule.consumeSpellCheckers require.resolve('./known-1-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./known-2-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./known-3-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./known-4-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./eot-spec-checker.coffee')
      atom.config.set('spell-check.locales', ['en-US'])
      atom.config.set('spell-check.useLocales', false)
      editor.setText('eot')
      atom.config.set('spell-check.grammars', ['source.js'])

      waitsFor ->
        getMisspellingMarkers().length is 1

      runs ->
        editor.destroy()
        expect(getMisspellingMarkers().length).toBe 0

    it "correctly spelling k1a", ->
      spellCheckModule.consumeSpellCheckers require.resolve('./known-1-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./known-2-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./known-3-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./known-4-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./eot-spec-checker.coffee')
      atom.config.set('spell-check.locales', ['en-US'])
      atom.config.set('spell-check.useLocales', false)
      editor.setText('k1a eot')
      atom.config.set('spell-check.grammars', ['source.js'])

      waitsFor ->
        getMisspellingMarkers().length is 1

      runs ->
        editor.destroy()
        expect(getMisspellingMarkers().length).toBe 0

    it "correctly mispelling k2a", ->
      spellCheckModule.consumeSpellCheckers require.resolve('./known-1-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./known-2-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./known-3-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./known-4-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./eot-spec-checker.coffee')
      atom.config.set('spell-check.locales', ['en-US'])
      atom.config.set('spell-check.useLocales', false)
      editor.setText('k2a eot')
      atom.config.set('spell-check.grammars', ['source.js'])

      waitsFor ->
        getMisspellingMarkers().length is 2

      runs ->
        editor.destroy()
        expect(getMisspellingMarkers().length).toBe 0

    it "correctly mispelling k2a with text in middle", ->
      spellCheckModule.consumeSpellCheckers require.resolve('./known-1-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./known-2-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./known-3-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./known-4-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./eot-spec-checker.coffee')
      atom.config.set('spell-check.locales', ['en-US'])
      atom.config.set('spell-check.useLocales', false)
      editor.setText('k2a good eot')
      atom.config.set('spell-check.grammars', ['source.js'])

      waitsFor ->
        getMisspellingMarkers().length is 2

      runs ->
        editor.destroy()
        expect(getMisspellingMarkers().length).toBe 0

    it "word is both correct and incorrect is correct", ->
      spellCheckModule.consumeSpellCheckers require.resolve('./known-1-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./known-2-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./known-3-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./known-4-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./eot-spec-checker.coffee')
      atom.config.set('spell-check.locales', ['en-US'])
      atom.config.set('spell-check.useLocales', false)
      editor.setText('k0a eot')
      atom.config.set('spell-check.grammars', ['source.js'])

      waitsFor ->
        getMisspellingMarkers().length is 1

      runs ->
        editor.destroy()
        expect(getMisspellingMarkers().length).toBe 0

    it "word is correct twice is correct", ->
      spellCheckModule.consumeSpellCheckers require.resolve('./known-1-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./known-2-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./known-3-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./known-4-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./eot-spec-checker.coffee')
      atom.config.set('spell-check.locales', ['en-US'])
      atom.config.set('spell-check.useLocales', false)
      editor.setText('k0b eot')
      atom.config.set('spell-check.grammars', ['source.js'])

      waitsFor ->
        getMisspellingMarkers().length is 1

      runs ->
        editor.destroy()
        expect(getMisspellingMarkers().length).toBe 0

    it "word is incorrect twice is incorrect", ->
      spellCheckModule.consumeSpellCheckers require.resolve('./known-1-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./known-2-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./known-3-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./known-4-spec-checker.coffee')
      spellCheckModule.consumeSpellCheckers require.resolve('./eot-spec-checker.coffee')
      atom.config.set('spell-check.locales', ['en-US'])
      atom.config.set('spell-check.useLocales', false)
      editor.setText('k0c eot')
      atom.config.set('spell-check.grammars', ['source.js'])

      waitsFor ->
        getMisspellingMarkers().length is 2

      runs ->
        editor.destroy()
        expect(getMisspellingMarkers().length).toBe 0
