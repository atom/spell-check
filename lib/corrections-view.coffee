{$$, Range, SelectList} = require 'atom'

module.exports =
class CorrectionsView extends SelectList
  @viewClass: -> "corrections #{super} popover-list"

  editorView: null
  corrections: null
  misspellingRange: null
  aboveCursor: false

  initialize: (@editorView, @corrections, @misspellingRange) ->
    super

    @attach()

  itemForElement: (word) ->
    $$ ->
      @li word

  selectNextItem: ->
    super

    false

  selectPreviousItem: ->
    super

    false

  confirmed: (correction) ->
    @cancel()
    return unless correction
    @editorView.transact =>
      @editorView.setSelectedBufferRange(@editorView.bufferRangeForScreenRange(@misspellingRange))
      @editorView.insertText(correction)

  attach: ->
    @aboveCursor = false
    @setArray(@corrections)

    @editorView.appendToLinesView(this)
    @setPosition()
    @miniEditor.focus()

  getEmptyMessage: (itemCount) ->
    if itemCount is 0
      'No corrections'
    else
      super

  detach: ->
    super

    @editorView.focus()

  setPosition: ->
    { left, top } = @editorView.pixelPositionForScreenPosition(@misspellingRange.start)
    height = @outerHeight()
    potentialTop = top + @editorView.lineHeight
    potentialBottom = potentialTop - @editorView.scrollTop() + height

    if @aboveCursor or potentialBottom > @editorView.outerHeight()
      @aboveCursor = true
      @css(left: left, top: top - height, bottom: 'inherit')
    else
      @css(left: left, top: potentialTop, bottom: 'inherit')

  populateList: ->
    super

    @setPosition()
