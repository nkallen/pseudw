vm = require('vm')
fs = require('fs')
dom = require('./dom')

Sizzle = ->
  script = vm.createScript(fs.readFileSync(__dirname + "/../vendor/sizzle/src/sizzle.js", "utf8"), 'sizzle.js');
  document = new dom.DocumentShim
  sandbox = { window: { document: document }, console: console }
  script.runInNewContext(sandbox)
  sandbox.window.Sizzle

module.exports = Sizzle
