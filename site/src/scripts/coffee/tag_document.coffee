#!/usr/bin/env coffee

fs = require('fs')
util = require('pseudw-util')
greek = util.greek
treebank = util.treebank
libxml = require('libxmljs')

for file in fs.readdirSync(__dirname + '/../../../../treebank/data/')
  continue unless /0133\.xml$/.test(file)

  tags = fs.readFileSync("../treebank/data/#{file}", 'utf8')

  metadata = fs.readFileSync("/Users/nkallen/Workspace/Perseus/texts/1999.01/#{file.replace(/xml/, 'metadata.xml')}", 'utf8')
  doc = fs.readFileSync("/Users/nkallen/Workspace/Perseus/texts/1999.01/#{file}", 'utf8')

  divs = []
  tags = libxml.parseXml(tags)
  doc = libxml.parseXml(doc)

  title = metadata.find("//datum[@key='dc:Title']").text()
  words = tags.find("//word")
  for divNode in doc.find("//div1")
    type = divNode.attr('type').value()
    div =
      paras: []
      type: type
    divs.push(div)
    para = null
    for child in divNode.childNodes()
      switch child.name()
        when "milestone"
          throw "Expecting card" unless child.attr("unit").value() == "card"
        when "l" # line
          for lineChild in child.childNodes()
            switch lineChild.name()
              when "milestone"
                throw "Expecting para" unless lineChild.attr("unit").value() == "para"
                para = []
                div.paras.push(para)
              when "text"
                l = []
                para.push(l)
                line = lineChild.text()
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
                    console.warn("Warning: token mismatch on line '#{originalLine}'\n '#{token}' <=> '#{word}'")

                  word = treebank.wordNode2word(word)
                  l.push(word)
        else
#          console.log("skipping #{child.name()}")
  out = ""
  divNumber = 0
  for div in divs
    divNumber++
    try
      fs.mkdirSync(path = "src/main/resources/#{title.toLowerCase()}/books/#{divNumber}")
    catch e
      throw e unless e.code == 'EEXIST'
    fd = fs.openSync(path + "/text.html", 'w')
    lineNumber = 0
    out = "<section class='#{div.type.toLowerCase()}' data-number='#{divNumber}'>\n"
    for para in div.paras
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
    out += "</section>\n"
    fs.writeSync(fd, out)
    fs.closeSync(fd)