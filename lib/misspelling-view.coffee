CorrectionsView = null

module.exports =
class MisspellingView
  constructor: (bufferRange, @editor) ->
    @createMarker(bufferRange)
    @correctMispellingCommand = atom.commands.add atom.views.getView(@editor), 'spell-check:correct-misspelling', =>
      if @containsCursor()
        CorrectionsView ?= require './corrections-view'
        @correctionsView?.destroy()
        @correctionsView = new CorrectionsView(@editor, @getCorrections(), @marker)

  createMarker: (bufferRange) ->
    @marker = @editor.markBufferRange(bufferRange,
      invalidate: 'touch',
      replicate: false,
      persistent: false,
      maintainHistory: false
    )
    @editor.decorateMarker(@marker,
      type: 'highlight',
      class: 'spell-check-misspelling',
      deprecatedRegionClass: 'misspelling'
    )

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
