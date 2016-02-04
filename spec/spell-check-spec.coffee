describe "Spell check", ->
  [workspaceElement, editor, editorElement, spellCheckModule] = []

  textForMarker = (marker) ->
    editor.getTextInBufferRange(marker.getRange())

  getMisspellingMarkers = ->
    spellCheckModule.misspellingMarkersForEditor(editor)

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)

    waitsForPromise ->
      atom.packages.activatePackage('language-text')

    waitsForPromise ->
      atom.packages.activatePackage('language-javascript')

    runs ->
      atom.config.set('spell-check.grammars', [])

    waitsForPromise ->
      atom.workspace.open('sample.js')

    waitsForPromise ->
      atom.packages.activatePackage('spell-check').then ({mainModule}) ->
        spellCheckModule = mainModule

    runs ->
      jasmine.attachToDOM(workspaceElement)
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)

  it "decorates all misspelled words", ->
    editor.setText("This middle of thiss\nsentencts\n\nhas issues and the \"edn\" 'dsoe' too")
    atom.config.set('spell-check.grammars', ['source.js'])

    misspellingMarkers = null
    waitsFor ->
      misspellingMarkers = getMisspellingMarkers()
      misspellingMarkers.length > 0

    runs ->
      expect(misspellingMarkers.length).toBe 4
      expect(textForMarker(misspellingMarkers[0])).toEqual "thiss"
      expect(textForMarker(misspellingMarkers[1])).toEqual "sentencts"
      expect(textForMarker(misspellingMarkers[2])).toEqual "edn"
      expect(textForMarker(misspellingMarkers[3])).toEqual "dsoe"

  it "doesn't consider our company's name to be a spelling error", ->
    editor.setText("GitHub (aka github): Where codez are built.")
    atom.config.set('spell-check.grammars', ['source.js'])

    misspellingMarkers = null
    waitsFor ->
      misspellingMarkers = getMisspellingMarkers()
      misspellingMarkers.length > 0

    runs ->
      expect(misspellingMarkers.length).toBe 1
      expect(textForMarker(misspellingMarkers[0])).toBe "codez"

  it "hides decorations when a misspelled word is edited", ->
    editor.setText('notaword')
    advanceClock(editor.getBuffer().getStoppedChangingDelay())
    atom.config.set('spell-check.grammars', ['source.js'])

    misspellingMarkers = null
    waitsFor ->
      misspellingMarkers = getMisspellingMarkers()
      misspellingMarkers.length > 0

    runs ->
      expect(misspellingMarkers.length).toBe 1
      editor.moveToEndOfLine()
      editor.insertText('a')
      advanceClock(editor.getBuffer().getStoppedChangingDelay())

      misspellingMarkers = getMisspellingMarkers()

      expect(misspellingMarkers.length).toBe 1
      expect(misspellingMarkers[0].isValid()).toBe false

  describe "when spell checking for a grammar is removed", ->
    it "removes all the misspellings", ->
      editor.setText('notaword')
      advanceClock(editor.getBuffer().getStoppedChangingDelay())
      atom.config.set('spell-check.grammars', ['source.js'])

      misspellingMarkers = null
      waitsFor ->
        misspellingMarkers = getMisspellingMarkers()
        misspellingMarkers.length > 0

      runs ->
        expect(getMisspellingMarkers().length).toBe 1
        atom.config.set('spell-check.grammars', [])
        expect(getMisspellingMarkers().length).toBe 0

  describe "when spell checking for a grammar is toggled off", ->
    it "removes all the misspellings", ->
      editor.setText('notaword')
      advanceClock(editor.getBuffer().getStoppedChangingDelay())
      atom.config.set('spell-check.grammars', ['source.js'])
      
      misspellingMarkers = null
      waitsFor ->
        misspellingMarkers = getMisspellingMarkers()
        misspellingMarkers.length > 0

      runs ->
        expect(getMisspellingMarkers().length).toBe 1
        atom.commands.dispatch(workspaceElement, 'spell-check:toggle')
        expect(getMisspellingMarkers().length).toBe 0

  describe "when the editor's grammar changes to one that does not have spell check enabled", ->
    it "removes all the misspellings", ->
      editor.setText('notaword')
      advanceClock(editor.getBuffer().getStoppedChangingDelay())
      atom.config.set('spell-check.grammars', ['source.js'])

      waitsFor ->
        getMisspellingMarkers().length > 0

      runs ->
        expect(getMisspellingMarkers().length).toBe 1
        editor.setGrammar(atom.grammars.selectGrammar('.txt'))
        expect(getMisspellingMarkers().length).toBe 0

  describe "when 'spell-check:correct-misspelling' is triggered on the editor", ->
    describe "when the cursor touches a misspelling that has corrections", ->
      it "displays the corrections for the misspelling and replaces the misspelling when a correction is selected", ->
        editor.setText('tofether')
        advanceClock(editor.getBuffer().getStoppedChangingDelay())
        atom.config.set('spell-check.grammars', ['source.js'])

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
        editor.setText('zxcasdfysyadfyasdyfasdfyasdfyasdfyasydfasdf')
        advanceClock(editor.getBuffer().getStoppedChangingDelay())
        atom.config.set('spell-check.grammars', ['source.js'])

        waitsFor ->
          getMisspellingMarkers().length > 0

        runs ->
          atom.commands.dispatch editorElement, 'spell-check:correct-misspelling'
          expect(editorElement.querySelectorAll('.corrections').length).toBe 1
          expect(editorElement.querySelectorAll('.corrections li').length).toBe 0
          expect(editorElement.querySelector('.corrections').textContent).toBe "No corrections"

  describe "when the editor is destroyed", ->
    it "destroys all misspelling markers", ->
      editor.setText('mispelling')
      atom.config.set('spell-check.grammars', ['source.js'])

      waitsFor ->
        getMisspellingMarkers().length > 0

      runs ->
        editor.destroy()
        expect(getMisspellingMarkers().length).toBe 0
