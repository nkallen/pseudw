annotator = require('../../main/coffee/annotator.coffee')
TreebankAnnotator = annotator.TreebankAnnotator
SkippingAnnotator = annotator.SkippingAnnotator
SimpleAnnotator = annotator.SimpleAnnotator
FailoverAnnotator = annotator.FailoverAnnotator

describe 'TreebankAnnotator', ->
  it 'tokenizes given forms', ->
    treebank = [{form: 'this'}, {form: 'is'}, {form: 'a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series'}, {form: 'of'}, {form: 'words'}]
    annotator = new TreebankAnnotator(treebank)
    this.expect(annotator.annotate("this is a fairly long series of words")[0]).toEqual(treebank)

  it 'tokenizes with originalForm', ->
    treebank = [{originalForm: 'this is a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series of'}, {form: 'words'}]
    annotator = new TreebankAnnotator(treebank)
    this.expect(annotator.annotate("this is a fairly long series of words")[0]).toEqual(treebank)

  it 'tokenizes with partial sentences', ->
    treebank = [{originalForm: 'this is a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series of'}, {form: 'words'}]
    annotator = new TreebankAnnotator(treebank)
    this.expect(annotator.annotate("this is a fairly")[0]).toEqual(treebank[0..1])
    this.expect(annotator.annotate("long series of")[0]).toEqual(treebank[2..3])
    this.expect(annotator.annotate("words")[0]).toEqual(treebank[4..4])

describe 'SkippingAnnotator', ->
  it 'skips deleted words', ->
    treebank = [{form: 'this'}, {form: 'is'}, {form: 'a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series'}, {form: 'of'}, {form: 'words'}]
    annotator = new SkippingAnnotator(new TreebankAnnotator(treebank))
    this.expect(annotator.annotate("series of words")[0]).toEqual(treebank[5..])

  it 'wont loop forever', ->
    treebank = [{form: 'this'}, {form: 'is'}, {form: 'a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series'}, {form: 'of'}, {form: 'words'}]
    annotator = new SkippingAnnotator(new TreebankAnnotator(treebank))
    this.expect(annotator.annotate("totally unrelated stuff")[0]).toEqual([])

describe 'FailoverAnnotator', ->
  it 'handles inserted words', ->
    addition = [{form: 'stuff'}, {form: 'before'}]
    treebank = [{form: 'this', id: 1}, {form: 'is'}, {form: 'a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series'}, {form: 'of'}, {form: 'words'}]
    annotator = new FailoverAnnotator(new TreebankAnnotator(treebank), new SimpleAnnotator)
    this.expect(annotator.annotate("stuff before this is a fairly long series of words")[0]).toEqual(addition.concat(treebank))
