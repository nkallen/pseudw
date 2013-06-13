vm = require('vm')
fs = require('fs')

Sizzle = ->
  script = vm.createScript(fs.readFileSync(__dirname + "/../javascript/sizzle/sizzle.js", "utf8"), 'sizzle.js');
  sandbox = { window: { document: {} }, document: {}, console: console }
  script.runInNewContext(sandbox)
  sandbox.window.Sizzle

module.exports = Sizzle
