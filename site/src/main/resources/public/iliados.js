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
    return [
      $word.data('part-of-speech'),
      $word.data('person'),
      $word.data('number'),
      $word.data('tense'),
      $word.data('mood'),
      $word.data('voice'),
      $word.data('case'),
      $word.data('gender')
    ].filter(function(item) {return item}).join(', ')
  }
  var fudge = 5; // for descenders;
  var offset = Number($('.text').css('margin-top').slice(0, -2)) - fudge;
  function scrollTo(line) {
    $('html, body')
      .animate({
        scrollTop: $("div.line:eq(" + (line - 1) + ")").offset().top - offset
       }, 500);
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

      var $row = $this.parents(".row").first();
      var $lineNumber = $this.find('.line-number');
      var $note = $lineNumber.data('note');
      if ($note) {
        highlight($lineNumber).addClass('label-info');
        $info.find('h4')
          .text('Book ' + $this.parents('section.book').data('number') + ", line " + $this.text());
        $info.find('.content')
          .html($note.html());
        $row.after($infoWell);
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
        $('a.edit').show();
      }
    })
    .keyup(function(e) {
      if (e.which == 18) {
        $('a.edit').hide();
      }
    })
  $('a.edit').click(function() {
    reset();
    var $form = $infoPane.find('form')
    $form.show()
    $form.find('textarea').text($(this).data('xml')).attr('name', 'path[' + escape($(this).data('xpath')) + ']')
  })
  var params = {};
  window.location.search.slice(1).split('&').forEach(function(param) {
    var pair = param.split('=');
    params[pair[0]] = pair[1];
  });
  var start, end = params.end || "";
  $(".range .end").val(end);
  if (start = Number(params.start)) {
    scrollTo(start);
  }
  var $start = $('.range input.start'), $end = $('.range input.end');
  $(window).scroll(function(e) {
    var leftOffset = $(".text").offset().left;
    var $line = $(document.elementFromPoint(leftOffset, offset + fudge)).not("section").find('a.line-number').first();
    if ($line.length > 0) {
      var lineNumber = Number($line.text());
      $start.val(lineNumber).text(lineNumber);
      var end = Math.max(lineNumber, Number($end.val()));
      $end.val(end).text(end);
    }
  })

  $(".range input.start")
    .keypress(function(e) {
      if (e.which == 13) {
        var line = Number($(this).val());
        if (line) scrollTo(line);
      }
    })
    .blur(function(e) {
      var line = Number($(this).val());
    });
  $("#vocabulary .btn-primary").click(function() {
    $("#vocabulary .modal-body table").hide();
    $("#vocabulary-practice").show();
    return false;
  });
  if (params.hasOwnProperty('vocabulary')) $("a.vocabulary").click();
});
