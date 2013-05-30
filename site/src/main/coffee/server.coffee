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

textName2index = {}
textNames = []
startMem = process.memoryUsage().heapUsed
start = new Date
do ->
  for textName in fs.readdirSync(__dirname + '/../resources/texts/')
    console.log(textName, process.memoryUsage())
    textNames.push(textName)
    books = (book for book in fs.readdirSync(__dirname + "/../resources/texts/#{textName}/books/"))
      .sort((a, b) -> Number(a) - Number(b))
    xmls = for book in books
      libxml.parseXml(fs.readFileSync(__dirname + "/../resources/texts/#{textName}/books/#{book}/text.html", 'utf8'))
    textName2index[textName] = treebank.load(xmls)
console.log("Memory delta: #{process.memoryUsage().heapUsed - startMem}b")
console.log("Loaded data in #{new Date - start}ms")

searchTemplate = _.template(fs.readFileSync(__dirname + '/../resources/search/index.html', 'utf8'))
app.get('/', (req, res, next) ->
  res.charset = 'utf-8'
  res.type('text/html')
  html = searchTemplate(
    query: ''
    textNames: textNames
    selectedTextNames: textNames
    results: []
    page: 0
    error: null)
  res.send(200, html))

app.get('/search', (req, res, next) ->
  searchTemplate = _.template(fs.readFileSync(__dirname + '/../resources/search/index.html', 'utf8'))
  query = req.query.query
  selectedTextNames =
    if req.query.texts
      if Array.isArray(req.query.texts)
        req.query.texts
      else
        Array(req.query.texts)
    else
      textNames
  page = Number(req.query.page) || 0
  start = end = error = results = null
  try
    start = new Date
    results = for textName in selectedTextNames
      matches: textName2index[textName](query)
      name: textName

    end = new Date
  catch e
    error = e

  res.charset = 'utf-8'
  res.type('text/html')
  html = searchTemplate(
    textNames: textNames
    selectedTextNames: selectedTextNames
    query: query
    results: results
    page: page
    error: error
    time: end - start)
  res.send(200, html))

template = _.template(fs.readFileSync(__dirname + '/../resources/text.html', 'utf8'))
app.get('/:name/books/:book', (req, res, next) ->
  book = Number(req.params.book) || 1
  return res.status(404).end() unless /(\w|\s)+/.test(name = req.params.name)

  books = fs.readdir(__dirname + "/../resources/texts/#{name}/books/", (err, books) ->
    fs.readFile(__dirname + "/../resources/texts/#{name}/books/#{book}/text.html", 'utf8', (err, text) ->
      return res.status(404).end() if err?

      fs.readFile(__dirname + "/../resources/texts/#{name}/books/#{book}/lexicon.html", 'utf8', (err, lexicon) ->
        fs.readFile(__dirname + "/../resources/texts/#{name}/books/#{book}/notes.html", 'utf8', (err, notes) ->
          html = template(
            name: name
            books: books
            book: book
            text: text
            lexicon: lexicon
            notes: notes)

          res.charset = 'utf-8'
          res.type('text/html')
          res.send(200, html))))))

app.listen(process.env.PORT)