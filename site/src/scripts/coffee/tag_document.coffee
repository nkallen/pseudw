#!/usr/bin/env coffee

fs = require('fs')
greek = require('pseudw-util').greek
libxml = require('libxmljs')

fs.readFile('/Users/nkallen/Workspace/agdt-1.6/data/1999.01.0133.xml', 'utf8', (err, tags) ->
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

                    sentence = word.parent()
                    lemma = word.attr('lemma').value().replace(/1$/, '')
                    id = word.attr('id').value()
                    sentenceId = sentence.attr('id').value()
                    parentId = word.attr('head').value()

                    postag = word.attr('postag').value()
                    relation = word.attr('relation').value()
                    partOfSpeech = switch postag[0]
                      when 'n' then 'noun'
                      when 'v' then 'verb'
                      when 't' then 'participle'
                      when 'a' then 'adjective'
                      when 'd' then 'adverb'
                      when 'l' then 'article'
                      when 'g' then 'particle'
                      when 'c' then 'conjunction'
                      when 'r' then 'preposition'
                      when 'p' then 'pronoun'
                      when 'm' then 'numeral'
                      when 'i' then 'interjection'
                      when 'e' then 'exclamation'
                      when 'u' then 'punctuation'
                      when 'x' then 'irregular'
                      when '-' then null
                      else throw "Invalid part-of-speech #{postag[0]} #{word}"
                    person = switch postag[1]
                      when '1' then 'first'
                      when '2' then 'second'
                      when '3' then 'third'
                      when '-' then null
                      else throw "Invalid person #{postag[1]}"
                    number = switch postag[2]
                      when 's' then 'singular'
                      when 'd' then 'dual'
                      when 'p' then 'plural'
                      when '-' then null
                      else throw "Invalid number #{postag[2]}"
                    tense = switch postag[3]
                      when 'p' then 'present'
                      when 'i' then 'imperfect'
                      when 'r' then 'perfect'
                      when 'l' then 'pluperfect'
                      when 't' then 'future perfect'
                      when 'f' then 'future'
                      when 'a' then 'aorist'
                      when '-' then null
                      else throw "Invalid tense #{postag[3]}"
                    mood = switch postag[4]
                      when 'i' then 'indicative'
                      when 's' then 'subjunctive'
                      when 'o' then 'optative'
                      when 'n' then 'infinitive'
                      when 'm' then 'imperative'
                      when 'p' then null
                      when 'd' then 'gerund'
                      when 'g' then 'gerundive'
                      when '-' then null
                      else throw "Invalid mood #{postag[4]}"
                    voice = switch postag[5]
                      when 'a' then 'active'
                      when 'p' then 'passive'
                      when 'm' then 'middle'
                      when 'e' then 'middle-passive'
                      when '-' then null
                      else throw "Invalid voice #{postag[5]}"
                    gender = switch postag[6]
                      when 'm' then 'masculine'
                      when 'f' then 'feminine'
                      when 'n' then 'neuter'
                      when '-' then null
                      else throw "Invalid gender #{postag[6]}"
                    kase = switch postag[7]
                      when 'n' then 'nominative'
                      when 'g' then 'genitive'
                      when 'd' then 'dative'
                      when 'a' then 'accusative'
                      when 'v' then 'vocative'
                      when 'l' then 'locative'
                      when '-' then null
                      else throw "Invalid case #{postag[7]}"
                    degree = switch postag[8]
                      when 'c' then 'comparative'
                      when 's' then 'superlative'
                      when '-' then null
                      else throw "Invalid degree #{postag[7]}"
                    relation = 

                    l.push(
                      form: greek.betacode2unicode(form),
                      lemma: greek.betacode2unicode(lemma),
                      id: id,
                      sentenceId: sentenceId,
                      parentId: parentId,
                      partOfSpeech: partOfSpeech,
                      person: person,
                      number: number,
                      tense: tense,
                      mood: mood,
                      voice: voice,
                      gender: gender,
                      case: kase,
                      degree: degree,
                      relation: relation)

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
              if word.form.match(/[,:;.]/)
                out += word.form
              else
                out += sep + "<span data-lemma='#{word.lemma}' data-sentence-id='#{word.sentenceId}' data-id='#{word.id}' data-parent-id='#{word.parentId.toString()}'"
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
