# This is the task local handler for the manager so we can reuse the manager
# throughout the life of the task.
SpellCheckerManager = require './spell-check-manager'
instance = SpellCheckerManager
instance.isTask = true

# Because of the heavy use of configuration options for the packages and our
# inability to listen/access config settings from this process, we need to get
# the settings in a roundabout manner via sending messages through the process.
# This has an additional complexity because other packages may need to send
# messages through the main `spell-check` task so they can update *their*
# checkers inside the task process.
#
# Below the dispatcher for all messages from the server. The type argument is
# require, how it is handled is based on the type.
process.on "message", (message) ->
  switch
    when message.type is "global" then loadGlobalSettings message.global
    when message.type is "checker" then instance.addCheckerPath message.checkerPath
    # Quietly ignore unknown message types.

# This handles updating the global configuration settings for
# `spell-check` along with the built-in checkers (locale and knownWords).
loadGlobalSettings = (data) ->
  instance.setGlobalArgs data

# This is the function that is called by the views whenever data changes. It
# returns with the misspellings along with an identifier that will let the task
# wrapper route it to the appropriate view.
backgroundCheck = (data) ->
  misspellings = instance.check data, data.text
  {id: data.id, misspellings: misspellings.misspellings}

module.exports = backgroundCheck
