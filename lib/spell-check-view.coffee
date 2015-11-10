_ = require 'underscore-plus'
{CompositeDisposable, Range} = require 'atom'
MisspellingView = require './misspelling-view'
SpellCheckTask = require './spell-check-task'

module.exports =
class SpellCheckView
  @content: ->
    @div class: 'spell-check'

  constructor: (@editor) ->
    @disposables = new CompositeDisposable
    @views = []
    @task = new SpellCheckTask()

    @task.onDidSpellCheck (range, misspellings) =>
      @destroyViews(range)
      @addViews(misspellings) if @buffer?

    @disposables.add @editor.onDidChangePath =>
      @subscribeToBuffer()

    @disposables.add @editor.onDidChangeGrammar =>
      @subscribeToBuffer()

    @disposables.add atom.config.onDidChange 'editor.fontSize', =>
      @subscribeToBuffer()

    @disposables.add atom.config.onDidChange 'spell-check.grammars', =>
      @subscribeToBuffer()

    @subscribeToBuffer()

    @disposables.add @editor.onDidDestroy(@destroy.bind(this))

  destroy: ->
    @unsubscribeFromBuffer()
    @disposables.dispose()
    @task.terminate()

  unsubscribeFromBuffer: ->
    @destroyViews()

    if @buffer?
      @bufferOnDidChangeDisposable.dispose()
      @bufferOnDidStopChangingDisposable.dispose()
      @buffer = null

  subscribeToBuffer: ->
    @unsubscribeFromBuffer()

    if @spellCheckCurrentGrammar()
      @buffer = @editor.getBuffer()
      @ranges = []
      @bufferOnDidChangeDisposable = @buffer.onDidChange (e) =>
        @updateChanges(e)
      @bufferOnDidStopChangingDisposable = @buffer.onDidStopChanging =>
        @updateMisspellings()
      @updateMisspellings()

  spellCheckCurrentGrammar: ->
    grammar = @editor.getGrammar().scopeName
    _.contains(atom.config.get('spell-check.grammars'), grammar)

  # kill all the MisspellingViews which intersect with range
  destroyViews: (range) ->
    if not range? and @buffer?
      range = @buffer.getRange()
    newViews = []
    while view = @views.shift()
      if view.marker.getBufferRange().intersectsWith(range) or not @buffer?
        view.destroy()
      else
        newViews.push(view)
    @views = newViews

  addViews: (misspellings) ->
    for misspelling in misspellings
      view = new MisspellingView(misspelling, @editor)
      @views.push(view)

  # accumulate changes
  updateChanges: (event) ->
    added = false
    for range, i in @ranges
      if range.intersectsWith(event.newRange)
        @ranges[i] = range.union(event.newRange)
        added = true
    if not added
      @ranges.push(event.newRange)

  # expand range to include nearest word boundaries
  expandRange: (range) ->
    start = @getBeginningOfWordPosition(range.start)
    end = @getEndOfWordPosition(range.end)
    new Range(start, end)

  updateMisspellings: ->
    # this function is also called on load, when no changes have been made
    # in which case we spell-check the whole document.
    if @ranges.length == 0
      range = @buffer.getRange()
      @ranges.push(range)
    # dispatch a new task for each range
    for range in @ranges
      range = @expandRange(range)
      text = @buffer.getTextInRange(range)
      console.log(range, text)
      try
        @task.start(range, text)
      catch error
        # Task::start can throw errors atom/atom#3326
        console.warn('Error starting spell check task', error.stack ? error)
    @ranges = []

  # Utility functions

  # get the beginning of the word at this point. Copied from the Cursor library.
  getBeginningOfWordPosition: (point) ->
    allowPrevious = false
    currentBufferPosition = point
    previousNonBlankRow = @editor.buffer.previousNonBlankRow(currentBufferPosition.row) ? 0
    scanRange = [[previousNonBlankRow, 0], currentBufferPosition]

    beginningOfWordPosition = null
    @editor.backwardsScanInBufferRange (@wordRegExp(point)), scanRange, ({range, stop}) ->
      if range.end.isGreaterThanOrEqual(currentBufferPosition) or allowPrevious
        beginningOfWordPosition = range.start
      if not beginningOfWordPosition?.isEqual(currentBufferPosition)
        stop()

    if beginningOfWordPosition?
      beginningOfWordPosition
    else if allowPrevious
      new Point(0, 0)
    else
      currentBufferPosition

  # get the end of the word at this point. Copied from the Cursor library.
  getEndOfWordPosition: (point) ->
    allowNext = false
    currentBufferPosition = point
    scanRange = [currentBufferPosition, @editor.getEofBufferPosition()]

    endOfWordPosition = null
    @editor.scanInBufferRange (@wordRegExp(point)), scanRange, ({range, stop}) ->
      if allowNext
        if range.end.isGreaterThan(currentBufferPosition)
          endOfWordPosition = range.end
          stop()
      else
        if range.start.isLessThanOrEqual(currentBufferPosition)
          endOfWordPosition = range.end
        stop()

    endOfWordPosition ? currentBufferPosition

  # The correct regular expression to match words at the current scope. Copied from cursor library.
  wordRegExp: (point) ->
    includeNonWordCharacters = true
    nonWordCharacters = atom.config.get('editor.nonWordCharacters', scope: @editor.scopeDescriptorForBufferPosition(point))
    segments = ["^[\t ]*$"]
    segments.push("[^\\s#{_.escapeRegExp(nonWordCharacters)}]+")
    if includeNonWordCharacters
      segments.push("[#{_.escapeRegExp(nonWordCharacters)}]+")
    new RegExp(segments.join("|"), "g")
