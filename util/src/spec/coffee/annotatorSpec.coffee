annotator = require('../../main/coffee/annotator.coffee')
TreebankAnnotator = annotator.TreebankAnnotator
SkippingAnnotator = annotator.SkippingAnnotator
SimpleAnnotator = annotator.SimpleAnnotator
FailoverAnnotator = annotator.FailoverAnnotator

describe 'TreebankAnnotator', ->
  it 'tokenizes given forms', ->
    treebank = [{form: 'this'}, {form: 'is'}, {form: 'a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series'}, {form: 'of'}, {form: 'words'}]
    annotator = new TreebankAnnotator(treebank)
    @expect(annotator.annotate("this is a fairly long series of words")[0]).toEqual(treebank)

  it 'tokenizes with originalForm', ->
    treebank = [{originalForm: 'this is a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series of'}, {form: 'words'}]
    annotator = new TreebankAnnotator(treebank)
    @expect(annotator.annotate("this is a fairly long series of words")[0]).toEqual(treebank)

  it 'tokenizes with partial sentences', ->
    treebank = [{originalForm: 'this is a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series of'}, {form: 'words'}]
    annotator = new TreebankAnnotator(treebank)
    @expect(annotator.annotate("this is a fairly")[0]).toEqual(treebank[0..1])
    @expect(annotator.annotate("long series of")[0]).toEqual(treebank[2..3])
    @expect(annotator.annotate("words")[0]).toEqual(treebank[4..4])

describe 'SkippingAnnotator', ->
  it 'skips deleted words', ->
    treebank = [{form: 'this'}, {form: 'is'}, {form: 'a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series'}, {form: 'of'}, {form: 'words'}]
    annotator = new SkippingAnnotator(new TreebankAnnotator(treebank))
    @expect(annotator.annotate("series of words")[0]).toEqual(treebank[5..])

  it 'wont loop forever', ->
    treebank = [{form: 'this'}, {form: 'is'}, {form: 'a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series'}, {form: 'of'}, {form: 'words'}]
    annotator = new SkippingAnnotator(new TreebankAnnotator(treebank))
    @expect(annotator.annotate("totally unrelated stuff")[0]).toEqual([])

describe 'FailoverAnnotator', ->
  it 'handles inserted words', ->
    addition = [{form: 'stuff'}, {form: 'before'}]
    treebank = [{form: 'this', id: 1}, {form: 'is'}, {form: 'a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series'}, {form: 'of'}, {form: 'words'}]
    annotator = new FailoverAnnotator(new TreebankAnnotator(treebank), new SimpleAnnotator)
    @expect(annotator.annotate("stuff before this is a fairly long series of words")[0]).toEqual(addition.concat(treebank))

describe 'Complicated Differences', ->
  it 'works reasonably well', ->

    treebank = [{form: 'this', id: 1}, {form: 'is'}, {form: 'a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series'}, {form: 'of'}, {form: 'words', id: 5}]
    annotator =
      new FailoverAnnotator(
        new TreebankAnnotator(treebank),
        new FailoverAnnotator(
          new SkippingAnnotator(new TreebankAnnotator(treebank)),
          new SimpleAnnotator))
    @expect(annotator.annotate("this a fairly ADDITION long series of words")[0]).toEqual([ { form : 'this', id : 1, __position__ : 0 }, { form : 'a', __position__ : 2 }, { form : 'fairly', __position__ : 3 }, { form : 'ADDITION' }, { form : 'long', __position__ : 4 }, { form : 'series', __position__ : 5 }, { form : 'of', __position__ : 6 }, { form : 'words', id : 5, __position__ : 7 } ])
