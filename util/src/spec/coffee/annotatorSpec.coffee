annotate = require('../../main/coffee/annotator.coffee')

describe 'TreebankAnnotate', ->
  it 'tokenizes given forms', ->
    treebank = [{form: 'this'}, {form: 'is'}, {form: 'a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series'}, {form: 'of'}, {form: 'words'}]
    annotater = new annotate.TreebankAnnotator(treebank)
    this.expect(annotater.annotate("this is a fairly long series of words")).toEqual(treebank)

  it 'tokenizes with originalForm', ->
    treebank = [{originalForm: 'this is a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series of'}, {form: 'words'}]
    annotater = new annotate.TreebankAnnotator(treebank)
    this.expect(annotater.annotate("this is a fairly long series of words")).toEqual(treebank)

  it 'tokenizes with partial sentences', ->
    treebank = [{originalForm: 'this is a'}, {form: 'fairly'}, {form: 'long'}, {form: 'series of'}, {form: 'words'}]
    annotater = new annotate.TreebankAnnotator(treebank)
    this.expect(annotater.annotate("this is a fairly")).toEqual(treebank[0..1])
    this.expect(annotater.annotate("long series of")).toEqual(treebank[2..3])
    this.expect(annotater.annotate("words")).toEqual(treebank[4..4])