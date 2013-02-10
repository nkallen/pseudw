#!/usr/bin/env coffee

fs = require('fs')
greek = require('pseudw-util').greek
libxml = require('libxmljs')
mysql = require('mysql')

help = "
Import the Perseus Dictionary data into a Database

Provide path to dictionary file on command line, e.g.,

  ./import_lexicon.coffee .../ml.xml
"

CHUNK_SIZE = 1000

connection = mysql.createConnection({
  host     : 'localhost',
  user     : process.env.DB_USER,
  password : process.env.DB_PASS,
  database : 'pseudw',
})

connection.connect((err) ->
  throw err if err?
)

file = fs.readFileSync(process.argv[2], 'utf8')
console.log("Parsing XML document...")
doc = new libxml.parseXmlString(file)
console.log("... successfully parsed.")
entries = doc.find("//entry")
totalInserts = 0

insertChunk = ->
  if entries.length == 0
    connection.end((err) ->
      throw err if err?
    )
    return

  sanitize = (chunk) ->
    for item in chunk
      tr = (item.get(".//sense//tr") || item.get(".//ref"))?.text()
      [
        greek.betacode2unicode(item.attr("key").value()),
        tr
      ]

  [chunk, entries] = [entries[0...CHUNK_SIZE], entries[CHUNK_SIZE..]]
  values = sanitize(chunk)
  connection.query(
    "INSERT INTO lexemes (`lemma`, `translation`) VALUES ?",
    [values],
  (err, rows, fields) =>
    throw err if err?

    totalInserts += values.length
    console.log("Inserted #{totalInserts} items so far")
    insertChunk()
  )

insertChunk()
