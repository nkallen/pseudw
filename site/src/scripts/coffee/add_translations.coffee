#!/usr/bin/env coffee

fs = require('fs')
greek = require('pseudw-util').greek
libxml = require('libxmljs')
unorm = require('unorm')
mysql = require('mysql')

connection = mysql.createConnection({
  host     : 'localhost',
  user     : process.env.DB_USER,
  password : process.env.DB_PASS,
  database : 'pseudw'})

connection.connect((err) ->
  throw err if err?)

fs.readFile('/Users/nkallen/Workspace/pseudw/site/src/main/resources/iliad.html', 'utf8', (err, doc) ->
  throw err if err?

  lemmas = {}
  doc = libxml.parseXml(doc)

  words = doc.find("//span[@class='word']")
  for word in words
    lemmas[unorm.nfc(word.attr('data-lemma').value())] = true
  connection.query(
    "SELECT * FROM lexemes WHERE lemma IN (?)",
    [Object.keys(lemmas)],
  (err, rows, fields) =>
    throw err if err?

    out = "<ul>\n"
    for row in rows
      out += "  <li data-lemma='#{row.lemma}'>#{row.translation}</li>\n"
    out += "</ul>"
    console.log(out)

    connection.end((err) ->
      throw err if err?)))