express = require('express')
mysql = require('mysql')
unorm = require('unorm')
Bundler = require('./bundler')
ParticipleDao = require('./participle_dao').sql
greek = require('pseudw-util').greek

DELIMITER = /[;, ]/

connection = mysql.createConnection({
  host     : 'localhost',
  user     : process.env.DB_USER,
  password : process.env.DB_PASS,
  database : 'pseudw',
})
connection.connect((err) ->
  throw err if err?
)
participleDao = new ParticipleDao(connection)

bundler = new Bundler(module, require)
bundler.dependency('pseudw-module1')
bundler.dependency('./participle_dao', 'participle-dao')
bundler.dependency('querystring')

app = express()

app.use(express.compress())

app.get('/application.js', (req, res) ->
  res.charset = 'utf-8'
  res.type('application/javascript')
  res.end(bundler.toString())
)

app.use(express.static(__dirname + '/../resources'))

app.get('/lemmas/:lemmas/participles', (req, res, next) ->
  lemmas = (unorm.nfc(lemma) for lemma in req.params.lemmas.split(DELIMITER))
  options = {}
  for inflection in greek.Participle.allInflections
    inflectionLowerCase = inflection.toString().toLowerCase()

    if req.query[inflectionLowerCase] && attributes = req.query[inflectionLowerCase]
      options[inflection] = (inflection[attribute] for attribute in attributes)

  participleDao.findAllByLemma(lemmas, options,
    (participles) ->
      return res.status(404).end() if participles.length == 0
      
      res.json(participles)
    ,
    (error) ->
      next(new Error(error)))
)

app.listen(3000)