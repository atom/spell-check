describe "Spell check", ->
  [workspaceElement, editor, editorElement] = []

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
      atom.packages.activatePackage('spell-check')

    runs ->
      jasmine.attachToDOM(workspaceElement)
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)

  it "decorates all misspelled words", ->
    editor.setText("This middle of thiss sentencts has issues and the \"edn\" 'dsoe' too")
    atom.config.set('spell-check.grammars', ['source.js'])

    decorations = null

    waitsFor ->
      decorations = editor.getHighlightDecorations(class: 'spell-check-misspelling')
      decorations.length > 0

    runs ->
      expect(decorations.length).toBe 4
      expect(decorations[0].marker.getBufferRange()).toEqual [[0, 15], [0, 20]]
      expect(decorations[1].marker.getBufferRange()).toEqual [[0, 21], [0, 30]]
      expect(decorations[2].marker.getBufferRange()).toEqual [[0, 51], [0, 54]]
      expect(decorations[3].marker.getBufferRange()).toEqual [[0, 57], [0, 61]]

  it "hides decorations when a misspelled word is edited", ->
    editor.setText('notaword')
    advanceClock(editor.getBuffer().getStoppedChangingDelay())
    atom.config.set('spell-check.grammars', ['source.js'])

    decorations = null
    waitsFor ->
      decorations = editor.getHighlightDecorations(class: 'spell-check-misspelling')
      decorations.length > 0

    runs ->
      expect(decorations.length).toBe 1
      editor.moveToEndOfLine()
      editor.insertText('a')
      advanceClock(editor.getBuffer().getStoppedChangingDelay())
      decorations = editor.getHighlightDecorations(class: 'spell-check-misspelling')
      expect(decorations.length).toBe 1
      expect(decorations[0].marker.isValid()).toBe false

  describe "when spell checking for a grammar is removed", ->
    it "removes all the misspellings", ->
      editor.setText('notaword')
      advanceClock(editor.getBuffer().getStoppedChangingDelay())
      atom.config.set('spell-check.grammars', ['source.js'])

      decorations = null
      waitsFor ->
        editor.getHighlightDecorations(class: 'spell-check-misspelling').length > 0

      runs ->
        expect(editor.getHighlightDecorations(class: 'spell-check-misspelling').length).toBe 1
        atom.config.set('spell-check.grammars', [])
        expect(editor.getHighlightDecorations(class: 'spell-check-misspelling').length).toBe 0

  describe "when spell checking for a grammar is toggled off", ->
    it "removes all the misspellings", ->
      editor.setText('notaword')
      advanceClock(editor.getBuffer().getStoppedChangingDelay())
      atom.config.set('spell-check.grammars', ['source.js'])

      waitsFor ->
        editor.getHighlightDecorations(class: 'spell-check-misspelling').length > 0

      runs ->
        expect(editor.getHighlightDecorations(class: 'spell-check-misspelling').length).toBe 1
        atom.commands.dispatch(workspaceElement, 'spell-check:toggle')
        expect(editor.getHighlightDecorations(class: 'spell-check-misspelling').length).toBe 0

  describe "when the editor's grammar changes to one that does not have spell check enabled", ->
    it "removes all the misspellings", ->
      editor.setText('notaword')
      advanceClock(editor.getBuffer().getStoppedChangingDelay())
      atom.config.set('spell-check.grammars', ['source.js'])

      waitsFor ->
        editor.getHighlightDecorations(class: 'spell-check-misspelling').length > 0

      runs ->
        expect(editor.getHighlightDecorations(class: 'spell-check-misspelling').length).toBe 1
        editor.setGrammar(atom.grammars.selectGrammar('.txt'))
        expect(editor.getHighlightDecorations(class: 'spell-check-misspelling').length).toBe 0

  describe "when 'spell-check:correct-misspelling' is triggered on the editor", ->
    describe "when the cursor touches a misspelling that has corrections", ->
      it "displays the corrections for the misspelling and replaces the misspelling when a correction is selected", ->
        editor.setText('tofether')
        advanceClock(editor.getBuffer().getStoppedChangingDelay())
        atom.config.set('spell-check.grammars', ['source.js'])

        waitsFor ->
          editor.getHighlightDecorations(class: 'spell-check-misspelling').length > 0

        runs ->
          atom.commands.dispatch editorElement, 'spell-check:correct-misspelling'

          correctionsElement = editorElement.querySelector('.corrections')
          expect(correctionsElement).toBeDefined()
          expect(correctionsElement.querySelectorAll('li').length).toBeGreaterThan 0
          expect(correctionsElement.querySelectorAll('li')[0].textContent).toBe "together"

          atom.commands.dispatch correctionsElement, 'core:confirm'

          expect(editor.getText()).toBe 'together'
          expect(editor.getCursorBufferPosition()).toEqual [0, 8]
          advanceClock(editor.getBuffer().getStoppedChangingDelay())
          expect(editorElement.querySelectorAll('.spell-check-misspelling').length).toBe 0
          expect(editorElement.querySelector('.corrections')).toBeNull()

    describe "when the cursor touches a misspelling that has no corrections", ->
      it "displays a message saying no corrections found", ->
        editor.setText('zxcasdfysyadfyasdyfasdfyasdfyasdfyasydfasdf')
        advanceClock(editor.getBuffer().getStoppedChangingDelay())
        atom.config.set('spell-check.grammars', ['source.js'])

        waitsFor ->
          editor.getHighlightDecorations(class: 'spell-check-misspelling').length > 0

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
        editor.getHighlightDecorations(class: 'spell-check-misspelling').length > 0

      runs ->
        editor.destroy()
        expect(editor.getMarkers().length).toBe 0
