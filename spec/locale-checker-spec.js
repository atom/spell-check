const LocaleChecker = require('../lib/locale-checker')
const env = require('../lib/checker-env')
const {it, fit, ffit} = require('./async-spec-helpers')

describe('Locale Checker', function () {
  it('can load en-US without paths', async function () {
    checker = new LocaleChecker('en-US', [])
    checker.deferredInit()

    expect(checker.isEnabled()).toEqual(true)
    expect(checker.getStatus()).toEqual(null)
  })

  it('cannot load xx-XX without paths', async function () {
    checker = new LocaleChecker('xx-XX', [])
    checker.deferredInit()

    expect(checker.isEnabled()).toEqual(false)
    expect(checker.getStatus())
      .toEqual('Cannot load the system dictionary for `xx-XX`.')
  })

  // On Windows, not using the built-in path should use the
  // Spelling API.
  if (env.isWindows()) {
    it('can load en-US from Windows API', async function () {
      checker = new LocaleChecker('en-US', [])
      checker.checkDictionaryPath = false;
      checker.checkDefaultPaths = false;
      checker.deferredInit()

      expect(checker.isEnabled()).toEqual(true)
      expect(checker.getStatus()).toEqual(null)
    })
  } else {
    it('cannot load en-US without paths or fallback', async function () {
      checker = new LocaleChecker('en-US', [])
      checker.checkDictionaryPath = false;
      checker.checkDefaultPaths = false;
      checker.deferredInit()

      expect(checker.isEnabled()).toEqual(false)
      expect(checker.getStatus()).toEqual('Cannot load the system dictionary for `en-US`.')
    })
  }
})
