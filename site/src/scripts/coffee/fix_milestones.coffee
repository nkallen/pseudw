#!/usr/bin/env coffee

fs = require('fs')
greek = require('pseudw-util').greek
libxml = require('libxmljs')

file = fs.readFileSync(path = process.argv[2], 'utf8')
console.log(path)
xml = libxml.parseXml(file)

for container in xml.find("//l/..")
  continue unless container.name() in ['sp', 'div1', 'div2']
  children = []
  para = null
  for child in container.childNodes()
    child.remove()
    switch child.name()
      when 'l'
        if child.get("./milestone[@unit='para']") || child.get("./milestone[@unit='Para']") || !para
          para = new libxml.Element(xml, 'p')

        para.addChild(child)
        children.push(para)
      else
        if para
          para.addChild(child)
        else
          children.push(child)

  for child in children
    container.addChild(child)

fs.writeSync(fs.openSync("#{path}", 'w'), xml.toString())