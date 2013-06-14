$(function() {
  function toTree($this) {
    var annotation = $this.data('annotation')
    var $p = $this.parents('.paragraph').first()
    var id2annotation = {}
    $p.find('.words > span').each(function() {
      var $this = $(this)
      var thisAnnotation = $this.data('annotation')
      
      if (annotation.sentenceId == thisAnnotation.sentenceId) {
        id2annotation[thisAnnotation.id] = thisAnnotation
      }
    })

    for (var id in id2annotation) {
      var annotation = id2annotation[id]
      var parent = id2annotation[annotation.parentId]
      if (!parent) continue

      (parent.children || (parent.children = [])).push(annotation)
      annotation.parent = parent
    }
  }

  var MAX_LEVEL = 4

  var sentence = {
    show: function() {
      var $this = $(this)
      var annotation = $this.data('annotation')

      $this.addClass('highlight').addClass('highlight').addClass('pivot')

      if (annotation.sentenceId) {
        if (!annotation.parent && !annotation.children)
          toTree($this)

        var node = annotation
        var level = 0
        while ((node = node.parent) && ++level <= MAX_LEVEL) {
          $('#' + node.sentenceId + '-' + node.id)
            .addClass('highlight')
            .addClass('parent')
            .css('opacity', 1.0 - (level / (MAX_LEVEL + 1)))
        }
        level = 0
        var bfs = [[annotation]]
        while ((nodes = bfs.pop()) && level++ <= MAX_LEVEL - 1) {
          var nextLevel = []
          for (n in nodes) {
            var node = nodes[n]
            nextLevel = nextLevel.concat(node.children || [])
            $('#' + node.sentenceId + '-' + node.id)
              .addClass('highlight')
              .addClass('child')
              .css('opacity', 1.0 - ((level-1) / (MAX_LEVEL-1)))
          }
          bfs.push(nextLevel)
        }
      }
    }
  }

  var lemma = {
    highlight: function() {
      var $this = $(this)
      var annotation = $this.data('annotation')
      setTimeout(function() {
        // Hack because jquery/sizzle can't handle unicode classnames:
        var wordsWithSameLemma = $(document.getElementsByClassName('lemma-' + annotation.lemma))
        wordsWithSameLemma.not($this).addClass('highlight')
      }, 50)
    }
  }

  var state = {
    edit: {
      enter: function() {
        $('a.edit').show()
        $('.words > span').off('click', info.show)
        $('.words > span').on('click', info.edit)
      },
      exit: function() {
        $('a.edit').hide()
        $('.words > span').off('click', info.edit)
        $('.words > span').on('click', info.show)
      }
    },

    reset: function() {
      $('.highlight, .child, .parent, .pivot')
        .removeClass('highlight child parent pivot')
        .attr('style', '')
      $('info-pane .word, .info-pane .paragraph').hide()
    }
  }

  var key = {
    filter: function(e) {
      if (e.which == 27) {
        $('body').trigger('reset')
      } else if (e.which == 18) {
        $('body').trigger('edit.' + (e.type == 'keydown' ? 'enter' : 'exit'))
      }
    }
  }

  var info = {
    word: function() {
      var $this = $(this)
      var annotation = $this.data('annotation')
      $('.info-pane')
        .find('.word').show()
          .find('h4').text(annotation.lemma).end()
          .find('h5 .label').text(annotation.form).end()
          .find('h5 .data').text(
            [
              annotation.partOfSpeech,
              annotation.person,
              annotation.number,
              annotation.tense,
              annotation.mood,
              annotation.voice,
              annotation.case,
              annotation.gender
            ].filter(function(item) {return item}).join(', '))
    },

    paragraph: function() {
      var $this = $(this)
      var xml = $this.data('xml')
      var path = $this.data('path')
      console.log($('.info-pane').find('.paragraph'))
      $('.info-pane')
        .find('.paragraph').show()
          .find('textarea')
            .text(xml)
            .attr('name', 'path[' + escape(path) + ']')

    }
  }

  $('.words > span')
    .click(state.reset)
    .click(info.word)
    .click(sentence.show)
    .click(lemma.highlight)
  $('a.edit')
    .click(state.reset)
    .click(info.paragraph)
  $('body').on('keydown', key.filter)
  $('body').on('keyup', key.filter)
  $('body').on('reset', state.reset)
  $('body').on('edit.enter', state.edit.enter)
  $('body').on('edit.exit', state.edit.exit)
  $('.info').on('show', info.show)
})
