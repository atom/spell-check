CorrectionsView = require './corrections-view'

module.exports =
class MisspellingView
  constructor: (bufferRange, editorView) ->
    @editor = editorView.getEditor()
    @createMarker(bufferRange)

    @correctMispellingCommand = atom.commands.add editorView.element, 'spell-check:correct-misspelling', =>
      if @containsCursor()
        @correctionsView?.remove()
        @correctionsView = new CorrectionsView(editorView, @getCorrections(), @marker.getScreenRange())

  createMarker: (bufferRange) ->
    @marker = @editor.markBufferRange(bufferRange, invalidate: 'touch', replicate: false, persistent: false)
    @editor.decorateMarker(@marker, type: 'highlight', class: 'spell-check-misspelling', deprecatedRegionClass: 'misspelling')

  getCorrections: ->
    screenRange = @marker.getScreenRange()
    misspelling = @editor.getTextInRange(@editor.bufferRangeForScreenRange(screenRange))
    SpellChecker = require 'spellchecker'
    corrections = SpellChecker.getCorrectionsForMisspelling(misspelling)

  containsCursor: ->
    cursor = @editor.getCursorScreenPosition()
    @marker.getScreenRange().containsPoint(cursor, false)

  destroy: ->
    @correctMispellingCommand?.dispose()
    @correctMispellingCommand = null

    @correctionsView?.remove()
    @correctionsView = null

    @marker?.destroy()
    @marker = null
