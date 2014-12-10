{Range} = require 'atom'
{SelectListView} = require 'atom-space-pen-views'

module.exports =
class CorrectionsView extends SelectListView
  initialize: (@editor, @corrections, @marker) ->
    super
    @addClass('corrections popover-list')
    @attach()

  attach: ->
    @setItems(@corrections)
    @overlayDecoration = @editor.decorateMarker(@marker, type: 'overlay', item: this)

  attached: ->
    @storeFocusedElement()
    @focusFilterEditor()

  destroy: ->
    @cancel()
    @remove()

  confirmed: (correction) ->
    @cancel()
    return unless correction
    @editor.transact =>
      @editor.selectMarker(@marker)
      @editor.insertText(correction)

  cancelled: ->
    @overlayDecoration.destroy()
    @restoreFocus()

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
