express = require('express')
pg = require('pg')
unorm = require('unorm')
Bundler = require('./bundler')
ParticipleDao = require('./participle_dao').sql
greek = require('pseudw-util').greek
fs = require('fs')
_ = require('underscore')

DELIMITER = /[;, ]/

dbClient =
  query: (query, bindParameters, cb) ->
    pg.connect(process.env.DATABASE_URL, (err, client) ->
      return cb(err) if err?

      client.query(query, bindParameters, cb))

participleDao = new ParticipleDao(dbClient)

bundler = new Bundler(module, require)
bundler.dependency('pseudw-module1')
bundler.dependency('./participle_dao', 'participle-dao')
bundler.dependency('querystring')

app = express()

app.use(express.compress())

app.get('/application.js', (req, res) ->
  res.charset = 'utf-8'
  res.type('application/javascript')
  res.end(bundler.toString()))

app.use(express.static(__dirname + '/../resources/public'))

app.get('/lemmas/:lemmas/participles', (req, res, next) ->
  lemmas = (unorm.nfc(lemma) for lemma in req.params.lemmas.split(DELIMITER))
  options = {}
  for inflection in greek.Participle.allInflections
    inflectionLowerCase = inflection.toString().toLowerCase()

    if attributes = req.query["#{inflectionLowerCase}s"]
      options["#{inflectionLowerCase}s"] = (inflection[attribute] for attribute in attributes)

  participleDao.findAllByLemma(lemmas, options, (error, participles) ->
    return next(new Error(error)) if error?
    return res.status(404).end() if participles.length == 0

    res.json(participles)))

iliad = _.template(fs.readFileSync(__dirname + '/../resources/iliad/iliad.html', 'utf8'))
app.get('/iliad/books/:book', (req, res, next) ->
  return res.status(404).end() unless 1 <= (book = Number(req.params.book)) <= 24

  fs.readFile(__dirname + "/../resources/iliad/books/#{book}/text.html", 'utf8', (err, text) ->
    return res.status(500).end() if err?

    fs.readFile(__dirname + "/../resources/iliad/books/#{book}/lexicon.html", 'utf8', (err, lexicon) ->
      return res.status(500).end() if err?

      fs.readFile(__dirname + "/../resources/iliad/books/#{book}/notes.html", 'utf8', (err, notes) ->
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