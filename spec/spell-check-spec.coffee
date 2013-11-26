{WorkspaceView} = require 'atom'

describe "Spell check", ->
  [editorView] = []

  beforeEach ->
    atom.packages.activatePackage('language-text', sync: true)
    atom.packages.activatePackage('language-javascript', sync: true)
    atom.workspaceView = new WorkspaceView
    atom.workspaceView.openSync('sample.js')
    atom.config.set('spell-check.grammars', [])
    atom.packages.activatePackage('spell-check', immediate: true)
    atom.workspaceView.attachToDom()
    editorView = atom.workspaceView.getActiveView()

  it "decorates all misspelled words", ->
    editorView.setText("This middle of thiss sentencts has issues.")
    atom.config.set('spell-check.grammars', ['source.js'])

    waitsFor ->
      editorView.find('.misspelling').length > 0

    runs ->
      expect(editorView.find('.misspelling').length).toBe 2

      typo1StartPosition = editorView.pixelPositionForBufferPosition([0, 15])
      typo1EndPosition = editorView.pixelPositionForBufferPosition([0, 20])
      expect(editorView.find('.misspelling:eq(0)').position()).toEqual typo1StartPosition
      expect(editorView.find('.misspelling:eq(0)').width()).toBe typo1EndPosition.left - typo1StartPosition.left

      typo2StartPosition = editorView.pixelPositionForBufferPosition([0, 21])
      typo2EndPosition = editorView.pixelPositionForBufferPosition([0, 30])
      expect(editorView.find('.misspelling:eq(1)').position()).toEqual typo2StartPosition
      expect(editorView.find('.misspelling:eq(1)').width()).toBe typo2EndPosition.left - typo2StartPosition.left

  it "hides decorations when a misspelled word is edited", ->
    editorView.setText('notaword')
    advanceClock(editorView.getBuffer().stoppedChangingDelay)
    atom.config.set('spell-check.grammars', ['source.js'])

    waitsFor ->
      editorView.find('.misspelling').length > 0

    runs ->
      expect(editorView.find('.misspelling').length).toBe 1
      editorView.moveCursorToEndOfLine()
      editorView.insertText('a')
      advanceClock(editorView.getBuffer().stoppedChangingDelay)
      expect(editorView.find('.misspelling')).toBeHidden()

  describe "when spell checking for a grammar is removed", ->
    it "removes all current decorations", ->
      editorView.setText('notaword')
      advanceClock(editorView.getBuffer().stoppedChangingDelay)
      atom.config.set('spell-check.grammars', ['source.js'])

      waitsFor ->
        editorView.find('.misspelling').length > 0

      runs ->
        expect(editorView.find('.misspelling').length).toBe 1
        atom.config.set('spell-check.grammars', [])
        expect(editorView.find('.misspelling').length).toBe 0

  describe "when 'editorView:correct-misspelling' is triggered on the editorView", ->
    describe "when the cursor touches a misspelling that has corrections", ->
      it "displays the corrections for the misspelling and replaces the misspelling when a correction is selected", ->
        editorView.setText('tofether')
        advanceClock(editorView.getBuffer().stoppedChangingDelay)
        atom.config.set('spell-check.grammars', ['source.js'])

        waitsFor ->
          editorView.find('.misspelling').length > 0

        runs ->
          editorView.trigger 'editorView:correct-misspelling'
          expect(editorView.find('.corrections').length).toBe 1
          expect(editorView.find('.corrections li').length).toBeGreaterThan 0
          expect(editorView.find('.corrections li:first').text()).toBe "together"
          editorView.find('.corrections').view().confirmSelection()
          expect(editorView.getText()).toBe 'together'
          expect(editorView.getCursorBufferPosition()).toEqual [0, 8]
          advanceClock(editorView.getBuffer().stoppedChangingDelay)
          expect(editorView.find('.misspelling')).toBeHidden()
          expect(editorView.find('.corrections').length).toBe 0

    describe "when the cursor touches a misspelling that has no corrections", ->
      it "displays a message saying no corrections found", ->
        editorView.setText('zxcasdfysyadfyasdyfasdfyasdfyasdfyasydfasdf')
        advanceClock(editorView.getBuffer().stoppedChangingDelay)
        atom.config.set('spell-check.grammars', ['source.js'])

        waitsFor ->
          editorView.find('.misspelling').length > 0

        runs ->
          editorView.trigger 'editorView:correct-misspelling'
          expect(editorView.find('.corrections').length).toBe 1
          expect(editorView.find('.corrections li').length).toBe 0
          expect(editorView.find('.corrections').view().error.text()).toBe "No corrections"

  describe "when the edit session is destroyed", ->
    it "destroys all misspelling markers", ->
      editorView.setText("mispelling")
      atom.config.set('spell-check.grammars', ['source.js'])

      waitsFor ->
        editorView.find('.misspelling').length > 0

      runs ->
        expect(editorView.find('.misspelling').length).toBe 1
        view = editorView.find('.misspelling').view()
        buffer = editorView.getBuffer()
        expect(view.marker.isDestroyed()).toBeFalsy()
        editorView.remove()
        expect(view.marker.isDestroyed()).toBeTruthy()
