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

dirs = []
processDir = (dir) ->
  console.log(dir)
  text = libxml.parseXml("<div>" + fs.readFileSync("#{dir}/text.html", 'utf8') + "</div>")
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
    fs.writeFileSync("#{dir}/lexicon.html", out)
    if dirs.length > 0
      processDir(dirs.pop())
    else
      connection.end((err) -> throw err if err?))

for text in fs.readdirSync(root = __dirname + '/../../main/resources/texts')
  for book in fs.readdirSync(part = "#{root}/#{text}/books")
    dirs.push("#{part}/#{book}")

processDir(dirs.pop())