{Range, View} = require 'atom'
CorrectionsView = require './corrections-view'

module.exports =
class MisspellingView extends View
  @content: ->
    @div class: 'misspelling'

  initialize: (range, @editorView) ->
    @editor = @editorView.getEditor()
    @misspellingValid = true
    @updateDisplayPosition = true

    range = @editor.screenRangeForBufferRange(Range.fromObject(range))
    @startPosition = range.start
    @endPosition = range.end
    @oldScreenRange = @getScreenRange()

    @createMarker()

    @subscribe @editorView, 'editor:display-updated', =>
      @updatePosition() if @isUpdateNeeded()

    @subscribeToCommand @editorView, 'spell-check:correct-misspelling', =>
      if @misspellingValid and @containsCursor()
        @correctionsView?.remove()
        @correctionsView = new CorrectionsView(@editorView, @getCorrections(), @getScreenRange())

    @updatePosition() if @isUpdateNeeded()

  createMarker: ->
    @marker = @editor.markScreenRange(@getScreenRange(), invalidation: 'touch', replicate: false, persistent: false)
    @subscribe @marker, 'changed', ({newHeadScreenPosition, newTailScreenPosition, isValid}) =>
      @startPosition = newTailScreenPosition
      @endPosition = newHeadScreenPosition
      @updateDisplayPosition = isValid
      @misspellingValid = isValid
      @hide() unless isValid

  isUpdateNeeded: ->
    return false unless @updateDisplayPosition

    oldScreenRange = @oldScreenRange
    newScreenRange = @getScreenRange()
    @oldScreenRange = newScreenRange
    @intersectsRenderedScreenRows(oldScreenRange) or @intersectsRenderedScreenRows(newScreenRange)

  intersectsRenderedScreenRows: (range) ->
    range.intersectsRowRange(@editorView.firstRenderedScreenRow, @editorView.lastRenderedScreenRow)

  getScreenRange: ->
    new Range(@startPosition, @endPosition)

  getCorrections: ->
    screenRange = @getScreenRange()
    misspelling = @editor.getTextInRange(@editor.bufferRangeForScreenRange(screenRange))
    SpellChecker = require 'spellchecker'
    corrections = SpellChecker.getCorrectionsForMisspelling(misspelling)

  beforeRemove: ->
    @marker.destroy()

  containsCursor: ->
    cursor = @editor.getCursorScreenPosition()
    @getScreenRange().containsPoint(cursor, exclusive: false)

  updatePosition: ->
    @updateDisplayPosition = false
    startPixelPosition = @editorView.pixelPositionForScreenPosition(@startPosition)
    endPixelPosition = @editorView.pixelPositionForScreenPosition(@endPosition)
    @css
      top: startPixelPosition.top
      left: startPixelPosition.left
      width: endPixelPosition.left - startPixelPosition.left
      height: @editorView.lineHeight
    @show()

  destroy: ->
    @misspellingValid = false
    @correctionsView?.remove()
    @remove()
