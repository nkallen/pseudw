#!/usr/bin/env coffee

fs = require('fs')
greek = require('pseudw-util').greek
libxml = require('libxmljs')

file = fs.readFileSync(path = process.argv[2], 'utf8')
xml = libxml.parseXml(file)

primaryLanguage = xml.get('//langUsage/language')?.attr('id').value()
if primaryLanguage == 'greek'
  for tag in ['l', 'speaker', 'p', 'head']
    for element in xml.find("//#{tag}")
      for child in element.childNodes()
        if child.name() == 'text'
          child.text(greek.betacode2unicode(child.text()))

for foreign in xml.find('//foreign')
  if foreign.attr('lang')?.value() == 'greek'
    foreign.text(greek.betacode2unicode(foreign.text()))

fs.writeSync(fs.openSync("#{path}", 'w'), xml.toString())