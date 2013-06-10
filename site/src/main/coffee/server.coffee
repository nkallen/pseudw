express = require('express')
util = require('pseudw-util')
greek = util.greek
treebank = util.treebank
TreebankAnnotator = util.annotator.TreebankAnnotator
index = util.perseus.index
fs = require('fs')
libxml = require('libxmljs')
_ = require('underscore')

app = express()
app.use(express.responseTime())
app.use(express.bodyParser())
app.use(express.methodOverride())
app.use(express.compress())
app.use(express.static(__dirname + '/../resources/public'))
app.set('view engine', 'ejs')
app.set('views', __dirname + '/../resources/views')

textName2index = {}
textNames = []
startMem = process.memoryUsage().heapUsed
start = new Date

do ->
  for textName in fs.readdirSync(__dirname + '/../resources/texts/')
    break
    global.gc()
    console.log(textName, process.memoryUsage())
    textNames.push(textName)
    books = (book for book in fs.readdirSync(__dirname + "/../resources/texts/#{textName}/books/"))
      .sort((a, b) -> Number(a) - Number(b))
    xmls = for book in books
      libxml.parseXml(fs.readFileSync(__dirname + "/../resources/texts/#{textName}/books/#{book}/text.html", 'utf8'))
    textName2index[textName] = treebank.load(xmls)

console.log("Memory delta: #{process.memoryUsage().heapUsed - startMem}b")
console.log("Loaded data in #{new Date - start}ms")

index = index.load(libxml.parseXml(fs.readFileSync(__dirname + '/../../../../perseus-greco-roman/index.xml')))
app.get('/:pid', (req, res, next) ->
  unless filename = index.file(req.params.pid)
    res.send(404)
    return
  annotations = index.annotations(req.params.pid)

  fs.readFile(__dirname + "/../../../../perseus-greco-roman/#{filename}", 'utf8', (err, xml) ->
    fs.readFile(__dirname + "/../../../../treebank-greek/data/json/#{annotations}", 'utf8', (err, annotations) ->
      xml = libxml.parseXml(xml).get('//body')
      annotations = JSON.parse(annotations)
      annotator = new TreebankAnnotator(annotations)

      res.render('text', text: xml, name: req.params.pid, annotator: annotator))))

app.patch('/pid/:pid', (req, res, next) ->
  unless filename = index.file(req.params.pid)
    res.send(404)
    return

  fs.readFile(path = __dirname + "/../../../../perseus-greco-roman/#{filename}", 'utf8', (err, xml) ->
    doc = libxml.parseXml(xml)
    for key, value of req.body.path
      node = doc.get(unescape(key))
      replacement = libxml.parseXml(value).root()
      node.addNextSibling(replacement)
      node.remove()

    fs.writeFile(path, doc.toString(), (err) ->
      res.redirect('/pid/' + req.params.pid))))


searchTemplate = _.template(fs.readFileSync(__dirname + '/../resources/search/index.html', 'utf8'))
app.get('/', (req, res, next) ->
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
  template = _.template(fs.readFileSync(__dirname + '/../resources/text.html', 'utf8'))
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

          res.type('text/html')
          res.send(200, html))))))

app.listen(process.env.PORT)