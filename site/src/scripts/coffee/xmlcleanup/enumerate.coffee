#!/usr/bin/env coffee

fs = require('fs')
greek = require('pseudw-util').greek
libxml = require('libxmljs')

file = fs.readFileSync(path = process.argv[2], 'utf8')
console.log(path)
xml = libxml.parseXml(file)

sampleLineNumber = xml.get(".//l[@n != '']")?.attr('n')?.value()
if !Number.isNaN(Number(sampleLineNumber))
  for b in xml.find("//body/div[@type='book']|//body/div[@type='act']")
    count = 1
    for l in b.find("./p/l|./sp/p/l")
      n = l.attr('n')?.value()
      if n
        if !Number.isNaN(Number(n))
          count = Number(n)
        else
          throw [n, count]
      l.attr('n', count++)

  fs.writeSync(fs.openSync("#{path}", 'w'), xml.toString())