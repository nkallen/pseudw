$(function() {
  $('a.dropdown-toggle, .dropdown-menu a').on('touchstart', function(e) {
    e.stopPropagation();
  }); // hack to fix menu navigation issue with bootstrap.

  var state = $();
  var $notes = $('ol.notes');
  var i = 0;
  var $infoPane = $('.info-pane');
  var $infoWell = $('.info-well').removeClass('prototype').remove();
  var $info = $infoPane.add($infoWell);
  var $form = $infoPane.find('form')
  var editMode = false;
  function reset() {
    $info.find('h4').text('');
    $info.find('h5').text('');
    $info.find('.content').text('');
    $infoWell.remove();
    state.each(function() {
      $(this).removeClass('highlight').removeClass('label-info').removeClass('label-important').removeAttr('style')
    });
    state = $();
  }
  reset();
  function highlight($item) {
    var result = $();
    $item.each(function () {
      var $this = $(this).addClass('highlight');
      result = result.add($this);
      state = state.add($this);
    });
    return result;
  }
  function inflections($word) {
    var annotation = $word.data('annotation')
    return [
      annotation.partOfSpeech,
      annotation.person,
      annotation.number,
      annotation.tense,
      annotation.mood,
      annotation.voice,
      annotation.case,
      annotation.gender
    ].filter(function(item) {return item}).join(', ')
  }
  $('a.line-number')
    .each(function() {
      var $this = $(this);
      if (++i % 5 == 0) $this.addClass('five');
      var $book = $this.parents('section.book');
      var $note = $notes.find('li[data-book="' + $book.data('number') + '"]').filter('[data-line="' + $this.text() + '"]');
      if ($note.length > 0) {
        $this
          .addClass('has-commentary')
          .data('note', $note)
      }
    })
  $('.line .span1:has(.line-number)')
    .click(function() {
      var $this = $(this);

      reset()

      var $row = $this.parents(".row").first()
      var $lineNumber = $this.find('.line-number')
      var $note = $lineNumber.data('note')
      if ($note) {
        highlight($lineNumber).addClass('label-info')
        $info.find('h4')
          .text('Book ' + $this.parents('section.book').data('number') + ", line " + $this.text())
        $info.find('.content')
          .html($note.html())
        $row.after($infoWell)
      }
    });

  lemma2word = {}
  $('.words span')
    .each(function() {
      var annotations = $(this).data('annotation')

      if (!lemma2word[annotations.lemma])
        lemma2word[annotations.lemma] = []

      lemma2word[annotations.lemma].push(this)
    })

  var $lexicon = $("ul.lexicon > li");
  var lexicon = {};
  $lexicon.each(function() {
    var $this = $(this);
    lexicon[$this.data('lemma')] = $this;
  })
  $('ul.lexicon').remove();   var start = new Date();
  var start = new Date();
  $('.words > span').click(function() {
    var $word = $(this);

    reset()

    var annotation = $word.data('annotation');
    var $row = $word.parents(".row").first();
    var lemma = annotation.lemma;

    var $translation = $(lexicon[lemma]);
    $info.find('h4').text(lemma);
    $info.find('h5')
      .html("<span class='label'>" + $word.text() + "</span> ")
      .append(inflections($word));
    $info.find('.content').html($translation.html());
    $row.after($infoWell);

    var start = new Date();
    var $p = $word.parents('.paragraph').first();

    if (annotation.sentenceId) {
      var $sentence = $p.find('.words > span').filter(function() { return $(this).data('annotation').sentenceId == annotation.sentenceId })

      var $parent     = $word;
      var parents     = [];

      while (($parent = $sentence.filter(function() { return $(this).data('annotation').id == $parent.data('annotation').parentId })) && $parent.length) {
        parents.push($parent);
      }

      var bfs   = [$word];
      var stack = [$word];
      var depth = 0;
      while (stack.length > 0) {
        if (++depth > 2) break;
        var $current  = stack.pop();
        var level = $();
        $current.each(function() {
          $this = $(this);
          var $children = $sentence.filter(function() { return $(this).data('annotation').parentId == $this.data('annotation').id });
          level = level.add($children);
        });
        if (level.length > 0) {
          stack.push(level);
          bfs.push(level);
        }
      };

      highlight($word).addClass('label-info')
      bfs.shift();
      var level = 1; // pretend we skipped one
      bfs.forEach(function(nodes) {
        var opacity = 1.0 - level++ / (bfs.length + 1);
        highlight(nodes)
          .css('opacity', opacity)
          .addClass('label-info');
      });
      level = 1; // pretend we skipped one
      parents.forEach(function(parent) {
        var opacity = 1.0 - (level++ / (parents.length + 1));
        highlight(parent)
          .css('opacity', opacity)
          .addClass('label-important');
      });
    }
    if (editMode) {
      $form.show()
      $form.find('textarea').text(JSON.stringify(annotation, null, "\t")).attr('name', 'annotation')
    }
    setTimeout(function() {
      highlight($(lemma2word[lemma]).not($word)).addClass('highlight')
    }, 50)
  });

  $('body')
    .keydown(function(e) {
      if (e.which == 27) { // <ESC>
        $(".modal").modal('hide');
        reset();
      } else if (e.which == 18) {
        editMode = true;
        $('a.edit').show();
      }
    })
    .keyup(function(e) {
      if (e.which == 18) {
        editMode = false;
        $('a.edit').hide();
      }
    })
  $('a.edit').click(function() {
    reset();
    $form.show()
    $form.find('textarea').text($(this).data('xml')).attr('name', 'path[' + escape($(this).data('xpath')) + ']')
  })
});
