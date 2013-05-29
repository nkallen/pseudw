#!/usr/bin/env coffee

fs = require('fs')
greek = require('pseudw-util').greek
libxml = require('libxmljs')
unorm = require('unorm')
mysql = require('mysql')

connection = mysql.createConnection(
  host     : 'localhost',
  user     : process.env.DB_USER,
  password : process.env.DB_PASS,
  database : 'pseudw')

connection.connect((err) -> throw err if err?)

dirs = fs.readdirSync(path = 'src/main/resources/texts/iliad/books/')
processDir = (dir) ->
  text = libxml.parseXml(fs.readFileSync(path + "#{dir}/text.html", 'utf8'))
  lemmas = {}
  words = text.find("//div[@class='words span5']/span")
  for word in words
    lemmas[unorm.nfc(word.attr('data-lemma').value())] = true
  lemmas = Object.keys(lemmas)

  out = "<ul class='lexicon'>\n"
  processLemma = (lemma, oncomplete) ->
    connection.query(
      "SELECT * FROM lexemes WHERE lemma IN (?, ?) LIMIT 1",
      ["#{lemma}1", lemma],
    (err, rows, fields) =>
      throw err if err?

      for row in rows
        out += "  <li data-lemma='#{lemma}'>\n#{row.translation}\n</li>\n"

      if lemma = lemmas.pop()
        processLemma(lemma, oncomplete)
      else
        oncomplete())

  processLemma(lemmas.pop(), () ->
    out += "</ul>"
    fs.writeFileSync(path + "#{dir}/lexicon.html", out)
    if dirs.length > 0
      processDir(dirs.pop())
    else
      connection.end((err) -> throw err if err?))

processDir(dirs.pop())