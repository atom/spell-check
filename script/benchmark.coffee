#!/usr/bin/env coffee

handler = require '../lib/spell-check-handler'
fs = require 'fs'

pathToCheck = process.argv[2]
console.log("Spellchecking %s...", pathToCheck)

text = fs.readFileSync(pathToCheck, 'utf8')

t0 = Date.now()
result = handler({id: 1, text})
t1 = Date.now()

console.log("Found %d misspellings in %d milliseconds", result.misspellings.length, t1 - t0)
