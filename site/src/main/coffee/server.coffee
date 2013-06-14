express = require('express')
libxml = require('libxmljs')
fs = require('fs')
util = require('pseudw-util')
textIndex = util.textIndex
annotator = util.annotator
text = require('./routes/text')
# search = require('./routes/search')

###
  Global configuration
###

app = express()
app.use(express.responseTime())
app.use(express.bodyParser())
app.use(express.methodOverride())
app.use(express.compress())
app.use(express.static(__dirname + '/../resources/public'))
app.set('view engine', 'ejs')
app.set('views', __dirname + '/views')

###
  Route configuration
###

CTS_URN = /^(urn:cts:[^\/]+)/

RESOURCES_DIR = __dirname + '/../resources' 
TEXTS_DIR = __dirname + '/../../../../perseus-greco-roman'
TREEBANK_DIR = __dirname + '/../../../../treebank-greek/data/json'

PERSEUS_INDEX = textIndex.PerseusIndex.load(libxml.parseXml(fs.readFileSync(TEXTS_DIR + '/index.perseus.xml')), TEXTS_DIR)
CTS_INDEX = textIndex.CtsIndex.load(libxml.parseXml(fs.readFileSync(TEXTS_DIR + '/index.cts.xml')), PERSEUS_INDEX)
ANNOTATOR_INDEX = annotator.TreebankAnnotatorIndex.load(TREEBANK_DIR)

text = text.configure(
  perseusIndex:   PERSEUS_INDEX
  ctsIndex:       CTS_INDEX
  annotatorIndex: ANNOTATOR_INDEX)

# app.get('/search', search.index)

app.param('urn', (req, res, next, urn) ->
  if CTS_URN.test(urn)
    req.params.urn = urn
    next()
  else
    next('route'))

app.get('/:urn', text.load, text.show)
app.patch('/:urn', text.load, text.update)

app.get('/:urn/annotations', text.load, text.annotations.show)
app.patch('/:urn/annotations/:id', text.load, text.annotations.update)

app.get('/:group/:work', text.work)
app.get('/:group/:work/:edition', text.load, text.show)
app.patch('/:group/:work/:edition', text.load, text.update)

app.get('/:group', text.group)

app.listen(process.env.PORT)
