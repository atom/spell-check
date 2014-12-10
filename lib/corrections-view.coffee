{Range} = require 'atom'
{SelectListView} = require 'atom-space-pen-views'

module.exports =
class CorrectionsView extends SelectListView
  initialize: (@editorView, @corrections, @marker) ->
    super
    @editor = @editorView.getModel()
    @addClass('corrections popover-list')
    @attach()

  attach: ->
    @setItems(@corrections)
    @overlayDecoration = @editor.decorateMarker(@marker, type: 'overlay', item: this)

  attached: ->
    @focusFilterEditor()

  confirmed: (correction) ->
    @cancel()
    return unless correction
    editor = @editorView.getEditor()
    editor.transact =>
      editor.selectMarker(@marker)
      editor.insertText(correction)
    @editorView.focus()

  cancelled: ->
    @overlayDecoration.destroy()

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

  getEmptyMessage: (itemCount) ->
    if itemCount is 0
      'No corrections'
    else
      super
