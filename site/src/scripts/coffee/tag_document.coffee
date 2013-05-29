#!/usr/bin/env coffee

fs = require('fs')
util = require('pseudw-util')
greek = util.greek
treebank = util.treebank
libxml = require('libxmljs')

words = null

handleLine = (node, paras) ->
  unless para = paras[paras.length-1]
    paras.push(para = [])
  for lineChild in node.childNodes()
    switch lineChild.name()
      when "milestone"
        throw "Expecting para" unless lineChild.attr("unit").value() == "para"
        paras.push(para = []) unless para == []
      when "text"
        l = []
        para.push(l)
        line = lineChild.text().trim()
        line = line.replace(/<|>/g, '') # hack
        originalLine = line
        while line.length > 0
          word = words.shift()
          form = word.attr('form').value()
          token = line[0..form.length-1]
          line = line[form.length..]
          if matches = line.match(/^\s+/)
            spaces = matches[0]
            line = line[spaces.length..]

          unless token == form
            if token in ['—', '†', '）', '（', '“', '”', ';']
              console.warn("Fixing token mismatch on line '#{line}'\n '#{token}' <=> '#{word}'")
              word.attr('form').value(token)
            else
              throw "Token mismatch on line '#{originalLine}'\n '#{token}' <=> '#{word}'"

          word = treebank.wordNode2word(word)
          l.push(word)

handleSpeech = (node) ->
  section =
    paras: []
    type: 'speech'
  section.speaker = greek.betacode2unicode(node.find("./speaker")[0].text())
  for line in node.find("./l")
    handleLine(line, section.paras)
  section

do ->
  for file in fs.readdirSync(__dirname + '/../../../../treebank/data/')
    continue unless /\.xml$/.test(file)
    continue unless file in ['1999.01.0003.xml', '1999.01.0005.xml', '1999.01.0133.xml', '1999.01.0135.xml', '1999.01.0127.xml', '1999.01.0129.xml', '1999.01.0131.xml']

    tags = fs.readFileSync("../treebank/data/#{file}", 'utf8')
    metadata = fs.readFileSync("/Users/nkallen/Workspace/Perseus/texts/1999.01/#{file.replace(/xml/, 'metadata.xml')}", 'utf8')
    doc = fs.readFileSync("/Users/nkallen/Workspace/Perseus/texts/1999.01/#{file}", 'utf8')

    divs = []
    metadata = libxml.parseXml(metadata)
    tags = libxml.parseXml(tags)
    doc = libxml.parseXml(doc)

    title = metadata.find("//datum[@key='dc:Title']")[0].text()
    console.log("Processing #{file}, #{title}")
    words = tags.find("//word")
    for divNode in doc.find("//div1")
      type = divNode.attr('type').value()
      div =
        sections: sections = [] # typically a speech or paragraph
        type: type
      divs.push(div)
      section = null
      for child in divNode.childNodes()
        switch child.name()
          when "milestone"
            throw "Expecting card" unless child.attr("unit").value() == "card"
          when "sp"
            sections.push(handleSpeech(child))
          when "l" # line
            unless section
              section =
                paras: []
                type: 'prose'
              sections.push(section)
            handleLine(child, section.paras)
          when "div2"
            for speech in child.find("./sp")
              sections.push(handleSpeech(speech))
          else
            # console.log("skipping #{child.name()}")
    out = ""
    divNumber = 0
    fd = null
    for div in divs
      if newBook = (divNumber++ == 0 || div.type == 'book')
        for path in ["src/main/resources/texts/#{title.toLowerCase()}", "src/main/resources/texts/#{title.toLowerCase()}/books", "src/main/resources/texts/#{title.toLowerCase()}/books/#{divNumber}"]
          try
            fs.mkdirSync(path)
          catch e
            throw e unless e.code == 'EEXIST'

        fd = fs.openSync(path + "/text.html", 'w')

      lineNumber = 0
      out = "<section class='#{div.type.toLowerCase()}' data-number='#{divNumber}'>\n"
      for section in div.sections
        if section.type == 'speech'
          out += "  <div class='speech'>\n"
          out += "    <div class='speaker'>#{section.speaker}</div>\n"
        for para in section.paras
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
                out += " data-part-of-speech='#{word.partOfSpeech}'" if word.partOfSpeech?
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
        if section.type == 'speech'
          out += "  </div>\n"
      out += "</section>\n"
      if newBook
        fs.writeSync(fd, out)
        fs.closeSync(fd)

    fs.writeSync(fs.openSync("../treebank/data/#{file}", 'w'), tags.toString())
