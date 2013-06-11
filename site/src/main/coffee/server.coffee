express = require('express')

text = require('./routes/text')
search = require('./routes/search')

app = express()
app.use(express.responseTime())
app.use(express.bodyParser())
app.use(express.methodOverride())
app.use(express.compress())
app.use(express.static(__dirname + '/../resources/public'))
app.set('view engine', 'ejs')
app.set('views', __dirname + '/views')

app.get('/search', search.index)
app.get('/:urn', text.show)
app.patch('/:urn', text.update)

app.listen(process.env.PORT)