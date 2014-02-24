{Range, SelectListView} = require 'atom'

module.exports =
class CorrectionsView extends SelectListView
  initialize: (@editorView, @corrections, @misspellingRange) ->
    super
    @addClass('corrections popover-list')
    @attach()

  viewForItem: (word) ->
    element = document.createElement('li')
    element.textContent = word
    element

  selectNextItemView: ->
    super
    false

  selectPreviousItemView: ->
    super
    false

  confirmed: (correction) ->
    @cancel()
    return unless correction
    editor = @editorView.getEditor()
    editor.transact =>
      editor.setSelectedBufferRange(editor.bufferRangeForScreenRange(@misspellingRange))
      editor.insertText(correction)
    @editorView.focus()

  attach: ->
    @aboveCursor = false
    @setItems(@corrections)

    @editorView.appendToLinesView(this)
    @setPosition()
    @focusFilterEditor()

  getEmptyMessage: (itemCount) ->
    if itemCount is 0
      'No corrections'
    else
      super

  setPosition: ->
    {left, top} = @editorView.pixelPositionForScreenPosition(@misspellingRange.start)
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
