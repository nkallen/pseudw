#!/usr/bin/env coffee

fs = require('fs')
greek = require('pseudw-util').greek
libxml = require('libxmljs')
unorm = require('unorm')

fs.readFile('/Users/nkallen/Workspace/pseudw/site/src/main/resources/iliad.html', 'utf8', (err, doc) ->
  throw err if err?

  fs.readFile('/Users/nkallen/Workspace/Perseus/texts/1999.04/1999.04.0083.xml', 'utf8', (err, notes) ->
    throw err if err?

    doc = libxml.parseXml(doc)
    notes = libxml.parseXml(notes)

    out = "<ul class='notes'>\n"
    for book in doc.find("//section[@class='book']")
      bookNumber = book.attr('data-number').value()
      notesForBook = notes.get("//div1[@type='book' and @n='#{bookNumber}']")
      for line in book.find("//div[@class='line']")
        lineNumber = line.attr('data-number').value()
        if notesForLine = notesForBook.get("div2[@type='commline' and @n='#{lineNumber}']")
          out += "  <li data-book='#{bookNumber}' data-line='#{lineNumber}'>\n#{notesForLine.text()}\n  </li>\n"

    out += "</ul>"
    console.log(out)))