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
      ref = ""
      if (senses = item.find(".//sense")).length > 0
        translation = "<ol class='entry'>\n"
        for sense in senses
          translation += "<li class='sense'>"
          for child in sense.childNodes()
            switch child.name()
              when "usg"
                translation += "<span class='usage'>#{child.text()}</span>"
              when "trans"
                trans = child
                for child in trans.childNodes()
                  switch child.name()
                    when "foreign"
                      word = greek.betacode2unicode(child.text())
                      translation += "<span class='ref' data-lemma='#{word}'>#{word}</span>"
                    when "text"
                      translation += child.text()
                    when "tr"
                      tr = child
                      for child in tr.childNodes()
                        switch child.name()
                          when "foreign"
                            if child.attr("lang").value() == "greek"
                              word = greek.betacode2unicode(child.text())
                              translation += "<span class='ref' data-lemma='#{word}'>#{word}</span>"
                            else
                              translation += "<span>child.text()</span>" # XXX latin?
                          when "text"
                            translation += "<span class='translation'>#{child.text()}</span>"
              when "text"
                translation += child.text()
              when "ref"
                if child.attr("lang").value() == "greek"
                  word = greek.betacode2unicode(child.text())
                  translation += "<span class='ref' data-lemma='#{word}'>#{word}</span>"
                else
                  translation += "<span>child.text()</span>" # DRY
              when "foreign"
                if child.attr("lang").value() == "greek"
                  word = greek.betacode2unicode(child.text())
                  translation += "<span class='ref' data-lemma='#{word}'>#{word}</span>"
                else
                  translation += child.text()
          translation += "</li>\n"
        translation += "</ol>"
      else if r = item.get(".//ref")
        ref = r.text()
      else
        console.error("==> Skipping:\n" + item.toString())
        continue
      [
        greek.betacode2unicode(item.attr("key").value()),
        translation,
        greek.betacode2unicode(ref)
      ]

  [chunk, entries] = [entries[0...CHUNK_SIZE], entries[CHUNK_SIZE..]]
  values = sanitize(chunk)
  connection.query(
    "INSERT INTO lexemes (`lemma`, `translation`, `ref`) VALUES ?",
    [values],
  (err, rows, fields) =>
    throw err if err?

    totalInserts += values.length
    console.log("Inserted #{totalInserts} items so far")
    insertChunk()
  )

insertChunk()
