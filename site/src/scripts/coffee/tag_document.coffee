#!/usr/bin/env coffee

fs = require('fs')
greek = require('pseudw-util').greek
libxml = require('libxmljs')

fs.readFile('/Users/nkallen/Workspace/Perseus/agdt-1.6/data/1999.01.0133.xml', 'utf8', (err, tags) ->
  throw err if err?

  fs.readFile('/Users/nkallen/Workspace/Perseus/texts/1999.01/1999.01.0133.xml', 'utf8', (err, doc) ->
    throw err if err?

    books = []
    tags = libxml.parseXml(tags)
    doc = libxml.parseXml(doc)

    words = tags.find("//word")
    for book in doc.find("//div1[@type='Book']")
      cards = []
      books.push(cards)
      card = null
      para = null
      for child in book.childNodes()
        switch child.name()
          when "milestone"
            throw "Expecting card" unless child.attr("unit").value() == "card"
            card = []
            cards.push(card)
          when "l" # line
            for lineChild in child.childNodes()
              switch lineChild.name()
                when "milestone"
                  throw "Expecting para" unless lineChild.attr("unit").value() == "para"
                  para = []
                  card.push(para)
                when "text"
                  l = []
                  para.push(l)
                  line = lineChild.text()
                  original_line = line
                  while line.length > 0
                    word = words.shift()
                    form = word.attr('form').value()
                    token = line[0..form.length-1]
                    line = line[form.length..]
                    if matches = line.match(/^\s+/)
                      spaces = matches[0]
                      line = line[spaces.length..]

                    unless token == form
                      console.warn("Warning: token mismatch on line '#{original_line}'\n '#{token}' <=> '#{word}'")

                    l.push(form: greek.betacode2unicode(form), lemma: greek.betacode2unicode(word.attr('lemma').value()))

    out = ""
    for book in books
      out += "<section class='book'>\n"
      for card in book
        out += "<section class='card'>\n"
        for para in card
          out += "<p>\n"
          for line in para
            out += "<div class='line'>"
            n = 0
            for word in line
              sep = if n > 0 then " " else ""
              if word.form.match(/[,:;.]/)
                out += word.form
              else
                out += sep + "<span class='word' data-lemma='#{word.lemma}'>#{word.form}</span>"
              n += 1
            out += "</div>\n"
          out += "</p>\n"
        out += "</section>\n"
      out += "</section>"

    console.log(out)
  )
)