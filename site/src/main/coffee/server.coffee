express = require('express')
pg = require('pg')
unorm = require('unorm')
greek = require('pseudw-util').greek
fs = require('fs')
libxml = require('libxmljs')
vm = require('vm')
_ = require('underscore')

DELIMITER = /[;, ]/

dbClient =
  query: (query, bindParameters, cb) ->
    pg.connect(process.env.DATABASE_URL, (err, client) ->
      return cb(err) if err?

      client.query(query, bindParameters, cb))


app = express()
app.use(express.compress())
app.use(express.static(__dirname + '/../resources/public'))

treeXml = fs.readFileSync(__dirname + '/../../../../treebank/data/1999.01.0133.xml', 'utf8')
tree = libxml.parseXml(treeXml)
tags =
  word: []

class Dom
  constructor: (@attributes, @nodeName) ->
    @children = []
    @parentNode = null
  nodeType: 1
  getAttribute: (attribute) ->
    @attributes[attribute]
  compareDocumentPosition: (that) -> 1
  getElementsByTagName: (name) ->
    if name == "*"
      @children
    else
      child for child in @children when child.nodeName == name

for sentenceNode in tree.find("//sentence")
  id2word = {}
  root = null
  for wordNode in sentenceNode.find("word")
    word = new Dom(greek.Treebank.wordNode2word(wordNode), "word")
    id2word[word.attributes.id] = word
    tags.word.push(word)
    if lemma = tags[word.attributes.lemma]
      lemma.push(word)
    else
      tags[word.attributes.lemma] = [word]
  for blah, word of id2word
    if word.attributes.parentId == '0'
      root = word
    else
      parent = id2word[word.attributes.parentId]
      parent.children.push(word)
      word.parentNode = parent

document =
  nodeType: 9
  getElementsByTagName: (name) ->
    if name == "*"
      tags.word
    else
      tags[name] || []
  documentElement:
    removeChild: () ->
  createComment : () -> {}
  createElement : () -> {}
  getElementById : () -> []

Sizzle = do ->
  script = vm.createScript(fs.readFileSync(__dirname + "/../../../../sizzle/sizzle.js", "utf8"), 'sizzle.js');
  sandbox = { window: {}, document: document, console: console }
  script.runInNewContext(sandbox)
  sandbox.window.Sizzle

# console.log(Sizzle('word[form=θεὰ][partOfSpeech=noun][number=singular][case=vocative]', document))
# :has([partOfSpeech=verb][mood=subjunctive])
# console.log(Sizzle('[partOfSpeech=verb][mood=indicative][tense=future] > εἰ[relation=AuxC]:has([partOfSpeech=verb][mood=subjunctive])', document).length)
search = _.template(fs.readFileSync(__dirname + '/../resources/search/index.html', 'utf8'))
app.get('/', (req, res, next) ->
  res.charset = 'utf-8'
  res.type('text/html')
  html = search(
    query: ''
    results: [])
  res.send(200, html))

app.get('/search', (req, res, next) ->
  search = _.template(fs.readFileSync(__dirname + '/../resources/search/index.html', 'utf8'))
  matches = Sizzle(query = req.query.query, document)
  results = for match in matches
    root = match
    while root.parentNode
      root = root.parentNode
    nodes = [root]
    i = 0
    while nodes.length > i
      nodes = nodes.concat(nodes[i].children)
      i++
    nodes.sort((node1, node2) -> node1.attributes.id - node2.attributes.id)

  res.charset = 'utf-8'
  res.type('text/html')
  html = search(
    query: query
    results: results)
  res.send(200, html))

iliad = _.template(fs.readFileSync(__dirname + '/../resources/iliad/iliad.html', 'utf8'))
app.get('/:name/books/:book', (req, res, next) ->
  return res.status(404).end() unless 1 <= (book = Number(req.params.book)) <= 24
  return res.status(404).end() unless /\w+/.test(name = req.params.name)

  iliad = _.template(fs.readFileSync(__dirname + '/../resources/iliad/iliad.html', 'utf8'))

  fs.readFile(__dirname + "/../resources/#{name}/books/#{book}/text.html", 'utf8', (err, text) ->
    return res.status(404).end() if err?

    fs.readFile(__dirname + "/../resources/#{name}/books/#{book}/lexicon.html", 'utf8', (err, lexicon) ->
      return res.status(500).end() if err?

      fs.readFile(__dirname + "/../resources/#{name}/books/#{book}/notes.html", 'utf8', (err, notes) ->
        return res.status(500).end() if err?

        html = iliad(
          book: book,
          text: text,
          lexicon: lexicon,
          notes: notes)

        res.charset = 'utf-8'
        res.type('text/html')
        res.send(200, html)))))

app.listen(process.env.PORT)