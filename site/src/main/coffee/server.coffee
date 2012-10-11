express = require('express')
pg = require('pg')
unorm = require('unorm')
Bundler = require('./bundler')
ParticipleDao = require('./participle_dao').sql
greek = require('pseudw-util').greek

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

app.use(express.static(__dirname + '/../resources'))

app.get('/lemmas/:lemmas/participles', (req, res, next) ->
  lemmas = (unorm.nfc(lemma) for lemma in req.params.lemmas.split(DELIMITER))
  options = {}
  for inflection in greek.Participle.allInflections
    inflectionLowerCase = inflection.toString().toLowerCase()

    if req.query[inflectionLowerCase] && attributes = req.query[inflectionLowerCase]
      options[inflection] = (inflection[attribute] for attribute in attributes)

  participleDao.findAllByLemma(lemmas, options, (error, participles) ->
    return next(new Error(error)) if error?
    return res.status(404).end() if participles.length == 0

    res.json(participles)))

app.listen(process.env.PORT)