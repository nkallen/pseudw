express = require('express')
pg = require('pg')
util = greek = require('pseudw-util')
greek = util.greek
treebank = util.treebank
fs = require('fs')
libxml = require('libxmljs')
_ = require('underscore')

app = express()
app.use(express.compress())
app.use(express.static(__dirname + '/../resources/public'))

start = new Date
docs = for book in fs.readdirSync(__dirname + '/../resources/iliad/books/')
  libxml.parseXml(fs.readFileSync(__dirname + "/../resources/iliad/books/#{book}/text.html", 'utf8'))
database = treebank.load(docs)
console.log("Loaded data in #{new Date - start}ms")

search = _.template(fs.readFileSync(__dirname + '/../resources/search/index.html', 'utf8'))
app.get('/', (req, res, next) ->
  res.charset = 'utf-8'
  res.type('text/html')
  html = search(
    query: ''
    results: []
    error: null)
  res.send(200, html))

app.get('/search', (req, res, next) ->
  search = _.template(fs.readFileSync(__dirname + '/../resources/search/index.html', 'utf8'))
  matches = []
  query = req.query.query
  page = Number(req.query.page) || 0
  error = null
  start = end = null
  try
    start = new Date
    matches = database(query)
    end = new Date
  catch e
    error = e

  res.charset = 'utf-8'
  res.type('text/html')
  html = search(
    query: query
    matches: matches
    page: page
    error: error
    time: end - start)
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