express = require('express')
text = require('./routes/text')
search = require('./routes/search')

CTS_URN = /^(urn:cts:.*)$/

app = express()
app.use(express.responseTime())
app.use(express.bodyParser())
app.use(express.methodOverride())
app.use(express.compress())
app.use(express.static(__dirname + '/../resources/public'))
app.set('view engine', 'ejs')
app.set('views', __dirname + '/views')


app.get('/search', search.index)
app.get('/:group/:work', text.work)
app.get('/:group/:work/:edition', text.load, text.show)
app.patch('/:group/:work/:edition', text.load, text.update)
app.param('urn', (req, res, next, urn) ->
  if CTS_URN.test(urn)
    req.params.urn = urn
    next()
  else
    next('route'))
app.get('/:urn', text.load, text.show)
app.patch('/:urn', text.load, text.update)
app.get('/:group', text.group)

app.listen(process.env.PORT)
