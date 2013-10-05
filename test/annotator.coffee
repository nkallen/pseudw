should = require('should')

annotator = require('../lib/annotator.coffee')
greek = require('../lib/greek.coffee')

TreebankAnnotator = annotator.TreebankAnnotator
SkippingAnnotator = annotator.SkippingAnnotator
SimpleAnnotator = annotator.SimpleAnnotator
FailoverAnnotator = annotator.FailoverAnnotator

describe 'SimpleAnnotator', ->
  it 'tokenizes at word boundaries, including punctuation', ->
    treebank = [{form: 'this'}, {form: 'is'}, {form: ','}, {form: 'a'}, {form: ';'}, {form: 'fairly'}, {form: '.'}]
    annotator = new SimpleAnnotator(greek)
    annotator.annotate("this is, a; fairly.")[0].should.eql(treebank)

describe 'TreebankAnnotator', ->
  it 'tokenizes given forms', ->
    treebank = [{form: 'this'}, {form: 'is'}, {form: 'a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series'}, {form: 'of'}, {form: 'words'}]
    annotator = new TreebankAnnotator(treebank)
    annotator.annotate("this is a fairly long series of words")[0].should.eql(treebank)

  it 'tokenizes with originalForm', ->
    treebank = [{originalForm: 'this is a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series of'}, {form: 'words'}]
    annotator = new TreebankAnnotator(treebank)
    annotator.annotate("this is a fairly long series of words")[0].should.eql(treebank)

  it 'tokenizes with partial sentences', ->
    treebank = [{originalForm: 'this is a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series of'}, {form: 'words'}]
    annotator = new TreebankAnnotator(treebank)
    annotator.annotate("this is a fairly")[0].should.eql(treebank[0..1])
    annotator.annotate("long series of")[0].should.eql(treebank[2..3])
    annotator.annotate("words")[0].should.eql(treebank[4..4])

describe 'SkippingAnnotator', ->
  it 'skips deleted words', ->
    treebank = [{form: 'this'}, {form: 'is'}, {form: 'a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series'}, {form: 'of'}, {form: 'words'}]
    annotator = new SkippingAnnotator(new TreebankAnnotator(treebank))
    annotator.annotate("series of words")[0].should.eql(treebank[5..])

  it 'wont loop forever', ->
    treebank = [{form: 'this'}, {form: 'is'}, {form: 'a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series'}, {form: 'of'}, {form: 'words'}]
    annotator = new SkippingAnnotator(new TreebankAnnotator(treebank))
    annotator.annotate("totally unrelated stuff")[0].should.eql([])

describe 'FailoverAnnotator', ->
  it 'handles inserted words', ->
    addition = [{form: 'stuff'}, {form: 'before'}]
    treebank = [{form: 'this', id: 1}, {form: 'is'}, {form: 'a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series'}, {form: 'of'}, {form: 'words'}]
    annotator = new FailoverAnnotator(new TreebankAnnotator(treebank), new SimpleAnnotator)
    annotator.annotate("stuff before this is a fairly long series of words")[0].should.eql(addition.concat(treebank))

describe 'Complicated Differences', ->
  it 'works reasonably well', ->

    treebank = [{form: 'this', id: 1}, {form: 'is'}, {form: 'a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series'}, {form: 'of'}, {form: 'words', id: 5}]
    annotator =
      new FailoverAnnotator(
        new TreebankAnnotator(treebank),
        new FailoverAnnotator(
          new SkippingAnnotator(new TreebankAnnotator(treebank)),
          new SimpleAnnotator))
    annotator.annotate("this a fairly ADDITION long series of words")[0]
      .should.eql([ { form : 'this', id : 1 }, { form : 'a' }, { form : 'fairly' }, { form : 'ADDITION' }, { form : 'long' }, { form : 'series' }, { form : 'of' }, { form : 'words', id : 5 } ])
