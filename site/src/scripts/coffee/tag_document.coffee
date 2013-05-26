#!/usr/bin/env coffee

fs = require('fs')
util = require('pseudw-util')
greek = util.greek
treebank = util.treebank
libxml = require('libxmljs')

fs.readFile('../treebank/data/1999.01.0133.xml', 'utf8', (err, tags) ->
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

                    word = treebank.wordNode2word(word)
                    l.push(word)

    out = ""
    bookNumber = 0
    for book in books
      bookNumber++
      try
        fs.mkdirSync(path = "src/main/resources/iliad/books/#{bookNumber}")
      catch e
        throw e unless e.code == 'EEXIST'
      fd = fs.openSync(path + "/text.html", 'w')
      lineNumber = 0
      out = "<section class='book' data-number='#{bookNumber}'>\n"
      cardNumber = 0
      for card in book
        out += "  <section class='card' data-number='#{++cardNumber}'>\n"
        for para in card
          out += "    <div class='paragraph'>\n"
          for line in para
            out += "      <div class='line'><div class='row'><div class='span1'><a class='line-number'>#{++lineNumber}</a></div><div class='words span5'>"
            n = 0
            for word in line
              sep = if n > 0 then " " else ""
              if word.partOfSpeech == 'punctuation'
                out += "<span data-lemma='#{word.lemma}' data-sentence-id='#{word.sentenceId}' data-id='#{word.id}' data-parent-id='#{word.parentId}' data-part-of-speech='#{word.partOfSpeech}' data-relation='#{word.relation}'>#{word.form}</span>"
              else
                out += sep + "<span data-lemma='#{word.lemma}' data-sentence-id='#{word.sentenceId}' data-id='#{word.id}' data-parent-id='#{word.parentId}'"
                out += " data-part-of-speech='#{word.partOfSpeech}'"
                out += " data-person='#{word.person}'" if word.person?
                out += " data-number='#{word.number}'" if word.number?
                out += " data-tense='#{word.tense}'" if word.tense?
                out += " data-mood='#{word.mood}'" if word.mood?
                out += " data-voice='#{word.voice}'" if word.voice?
                out += " data-gender='#{word.gender}'" if word.gender?
                out += " data-case='#{word.case}'" if word.case?
                out += " data-degree='#{word.degree}'" if word.degree?
                out += " data-relation='#{word.relation}'" if word.relation?
                out += ">#{word.form}</span>"
              n += 1
            out += "      </div></div></div>\n"
          out += "    </div>\n"
        out += "  </section>\n"
      out += "</section>\n"
      fs.writeSync(fd, out)
    fs.closeSync(fd)
  )
)
