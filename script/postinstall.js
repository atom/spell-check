#!/usr/bin/env node

const fs = require('fs')
const path = require('path')

// Remove the webworker-threads module in hopes of resolving the issue
// described in https://github.com/atom/spell-check/issues/67#issuecomment-377808833.
//
// webworker-threads is a dependency of natural, which is a dependency of
// spelling-manager, which is a dependency of this package.
// See: https://github.com/atom/spell-check/issues/67#issuecomment-380298141
const webworkerThreadsPath = path.join('node_modules', 'webworker-threads')
const rimraf = require('rimraf')
rimraf.sync(webworkerThreadsPath)
