module.exports =
  isLinux: -> /linux/.test process.platform
  isWindows: -> /win32/.test process.platform # TODO: Windows < 8 or >= 8
  isDarwin: -> /darwin/.test process.platform
  preferHunspell: -> !!process.env.SPELLCHECKER_PREFER_HUNSPELL

  isSystemSupported: -> @isWindows() or @isDarwin()
  isLocaleSupported: -> true

  useLocales: -> @isLinux() or @isWindows() or @preferHunspell()
