#!/usr/bin/env coffee

fs = require('fs')
greek = require('pseudw-util').greek
libxml = require('libxmljs')

output = new libxml.Document()
root = output
  .node("div")
  .attr(class: 'document')

fs.readFile('/Users/nkallen/Workspace/Perseus/agdt-1.6/data/1999.01.0133.xml', 'utf8', (err, tags) ->
  throw err if err?

  fs.readFile('/Users/nkallen/Workspace/Perseus/texts/1999.01/1999.01.0133.xml', 'utf8', (err, doc) ->
    throw err if err?

    tags = libxml.parseXml(tags)
    doc = libxml.parseXml(doc)

    words = tags.find("//word")
    books = doc.find("//div1[@type='Book']")
    for book in books
      section = root.node("section")
        .attr(class: 'book').text("\n")
      [card, para] = [null, null]
      for child in book.childNodes()
        switch child.name()
          when "milestone"
            throw "Expecting card" unless child.attr("unit").value() == "card"
            card = section.node("section")
              .attr(class: 'card').text("\n")
          when "l" # line
            for lineChild in child.childNodes()
              switch lineChild.name()
                when "milestone"
                  throw "Expecting para" unless lineChild.attr("unit").value() == "para"
                  para = card.node("p").text("\n")
                when "text"
                  l = para.node('div')
                    .attr(class: 'line').text("\n")
                  line = lineChild.text()
                  original_line = line
                  while line.length > 0
                    word = words.shift().attr('form').value()
                    token = line[0..word.length-1]
                    line = line[word.length..]
                    if matches = line.match(/^\s+/)
                      spaces = matches[0]
                      line = line[spaces.length..]
                      # l.addChild(spaces)
                      spaces = null

                    unless token == word
                      console.warn("Warning: token mismatch on line '#{original_line}'\n '#{token}' <=> '#{word}'")

                    l.node('span')
                      .attr(class: 'word')
                      .text(token)

    console.log(output.toString())
    )
)