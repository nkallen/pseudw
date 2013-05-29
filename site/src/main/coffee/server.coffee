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

databases = {}
startMem = process.memoryUsage().heapUsed
start = new Date

do ->
  for text in fs.readdirSync(__dirname + '/../resources/texts/')
    books = (book for book in fs.readdirSync(__dirname + "/../resources/texts/#{text}/books/"))
    books = books.sort((a, b) -> Number(a) - Number(b))
    docs = for book in books
      libxml.parseXml(fs.readFileSync(__dirname + "/../resources/texts/#{text}/books/#{book}/text.html", 'utf8'))
    databases[text] = treebank.load(docs)

console.log("Memory delta: #{process.memoryUsage().heapUsed - startMem}b")
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

all_databases = Object.keys(databases)
app.get('/search', (req, res, next) ->
  search = _.template(fs.readFileSync(__dirname + '/../resources/search/index.html', 'utf8'))
  query = req.query.query
  names = req.query.databases || all_databases
  page = Number(req.query.page) || 0
  start = end = error = results = null
  try
    start = new Date
    results = for name in names
      matches: databases[name](query)
      text: name

    end = new Date
  catch e
    error = e

  res.charset = 'utf-8'
  res.type('text/html')
  html = search(
    query: query
    results: results
    page: page
    error: error
    time: end - start)
  res.send(200, html))

template = _.template(fs.readFileSync(__dirname + '/../resources/text.html', 'utf8'))
app.get('/:name/books/:book', (req, res, next) ->
  return res.status(404).end() unless 1 <= (book = Number(req.params.book)) <= 24
  return res.status(404).end() unless /(\w|\s)+/.test(name = req.params.name)

  fs.readFile(__dirname + "/../resources/texts/#{name}/books/#{book}/text.html", 'utf8', (err, text) ->
    return res.status(404).end() if err?

    fs.readFile(__dirname + "/../resources/texts/#{name}/books/#{book}/lexicon.html", 'utf8', (err, lexicon) ->
      fs.readFile(__dirname + "/../resources/texts/#{name}/books/#{book}/notes.html", 'utf8', (err, notes) ->
        html = template(
          book: book,
          text: text,
          lexicon: lexicon,
          notes: notes)

        res.charset = 'utf-8'
        res.type('text/html')
        res.send(200, html)))))

app.listen(process.env.PORT)