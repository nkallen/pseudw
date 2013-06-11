fs = require('fs')
libxml = require('libxmljs')
util = require('pseudw-util')
treebank = util.treebank

textName2index = {}
textNames = []
startMem = process.memoryUsage().heapUsed
start = new Date

do ->
  for textName in fs.readdirSync(__dirname + '/../../resources/texts/')
    console.log(textName, process.memoryUsage())
    textNames.push(textName)
    books = (book for book in fs.readdirSync(__dirname + "/../../resources/texts/#{textName}/books/"))
      .sort((a, b) -> Number(a) - Number(b))
    xmls = for book in books
      libxml.parseXml(fs.readFileSync(__dirname + "/../../resources/texts/#{textName}/books/#{book}/text.html", 'utf8'))
    textName2index[textName] = treebank.load(xmls)
    break

console.log("Memory delta: #{process.memoryUsage().heapUsed - startMem}b")
console.log("Loaded data in #{new Date - start}ms")

index = (req, res) ->
  query = req.query.query

  if !query
    res.render('search',
      query: ''
      textNames: textNames
      selectedTextNames: textNames
      results: []
      page: 0
      error: null)
  else
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

    catch e
      error = e

    res.render('search',
      textNames: textNames
      selectedTextNames: selectedTextNames
      query: query
      raw: results
      page: page
      error: error
      time: new Date - start)

module.exports =
  index: index