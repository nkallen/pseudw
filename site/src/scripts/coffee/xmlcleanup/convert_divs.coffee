#!/usr/bin/env coffee

fs = require('fs')
greek = require('pseudw-util').greek
libxml = require('libxmljs')

file = fs.readFileSync(path = process.argv[2], 'utf8')
console.log(path)
xml = libxml.parseXml(file)

for div in xml.find("//div0|//div1|//div2|/div3|//div4|//div5")
  div.name('div')
  if type = div.attr('type')
    type.value(type.value().toLowerCase())

fs.writeSync(fs.openSync("#{path}", 'w'), xml.toString())