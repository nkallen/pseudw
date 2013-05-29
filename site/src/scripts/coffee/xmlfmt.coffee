#!/usr/bin/env coffee

fs = require('fs')
libxml = require('libxmljs')

path = process.argv[2]
console.log(path)
file = fs.readFileSync(path)
doc = libxml.parseXml(file)
fs.writeSync(fs.openSync("#{path}", 'w'), doc.toString())