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
  function reset(complete) {
    $info.find('h4').text('');
    $info.find('h5').text('');
    $info.find('.content').text('');
    $infoWell.remove();
    state.each(function() {
      $(this).removeClass('highlight').removeClass('label-info').removeClass('label-important').removeAttr('style')
    });
    state = $();
    complete && complete();
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

      reset(function() {
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
      })
    });

  var $lexicon = $("ul.lexicon > li");
  var lexicon = {};
  $lexicon.each(function() {
    var $this = $(this);
    lexicon[$this.data('lemma')] = $this;
  })
  $('ul.lexicon').remove();
  $('.words span').click(function() {
    var $word = $(this);

    reset(function() {
      var $row = $word.parents(".row").first();
      var lemma = $word.data('lemma');

      var $translation = $(lexicon[lemma]);
      $info.find('h4').text(lemma);
      $info.find('h5')
        .html("<span class='label'>" + $word.text() + "</span> ")
        .append(inflections($word));
      $info.find('.content').html($translation.html());
      $row.after($infoWell);

      var start = new Date();
      var $section  = $word.parents('.paragraph').first();
      if ($word.data('sentence-id')) {
        var $sentence = $section.find('span[data-sentence-id="' + $word.data('sentence-id') + '"]');

        var $parent     = $word;
        var parents     = [];
        while (($parent = $sentence.filter('span[data-id="' + $parent.data('parent-id') + '"]')) && $parent.length > 0) {
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
            var $children = $sentence.filter('span[data-parent-id="' + $this.data('id') + '"]');
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
        highlight($('span[data-lemma="' + lemma + '"]').not($word)).addClass('highlight')
      }, 50)
    })
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
  $('#thanks').tooltip();
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

  var $tableProto = $("#vocabulary table");
  var $carouselPrototype = $("#vocabulary #vocabulary-practice");
  var $theadProto = $("<thead><tr><td colspan='4' class='caption'></td></tr><tr><th>Lemma</th><th>Freq.</th><th>Common</th><th>Definition</th></tr></thead>");
  var $modalBody = $modalBody = $('#vocabulary .modal-body');
  var $lastLine = $(".line-number:last");
  $("a.vocabulary").click(function() {
    $modalBody.empty();
    $table = $tableProto.clone().appendTo($modalBody).removeClass("prototype");
    var vocabulary = {};
    var start = Number($start.val()) || 1;
    var end = Number($end.val() || $lastLine.text());
    $("#vocabulary .start").text(start);
    $("#vocabulary .end").text(end);
    $range = $("div.line").slice(start ? start - 1 : 0, end || undefined);
    $range.find('.words > span').each(function() {
      var self = $(this), wordsByPartOfSpeech;
      if (self.data('lemma')[0] == self.data('lemma')[0].toLowerCase()) { // skip proper nouns
        var partOfSpeech = self.data('part-of-speech');
        if (!vocabulary[partOfSpeech])
          vocabulary[partOfSpeech] = {};
        wordsByPartOfSpeech = vocabulary[partOfSpeech];
        var lemma = self.data('lemma');
        var text = self.text();

        if (wordsByPartOfSpeech[lemma] === undefined) {
          wordsByPartOfSpeech[lemma] = {count: 1, words: {}};
          wordsByPartOfSpeech[lemma].words[text] = {count: 1, word: self};
        } else {
          wordsByPartOfSpeech[lemma].count++;
          if (wordsByPartOfSpeech[lemma].words[text] == undefined) {
            wordsByPartOfSpeech[lemma].words[text] = {count: 1, word: self};
          } else {
            wordsByPartOfSpeech[lemma].words[text].count++;
          }
        }
      }
    });

    var $carousel = $carouselPrototype.clone().appendTo($modalBody);
    ['noun', 'adjective', 'verb', 'participle', 'adverb'].forEach(function(key) {
      var partOfSpeech = vocabulary[key];
      if (!partOfSpeech) return;

      var $thead = $theadProto.clone().appendTo($table);
      var $tbody = $("<tbody></tbody>").appendTo($table);
      var $caption = $thead.find(".caption");

      var lemmas = Object.keys(partOfSpeech).sort(function(a, b) { return partOfSpeech[b].count - partOfSpeech[a].count });
      $caption.text(key + " frequency");
      for (var i = 0; i < lemmas.length; i++) {
        if (i == (Number(params.limit || 30))) break;
        var lemma = lemmas[i];
        var words = partOfSpeech[lemma].words;
        var forms = Object.keys(words).sort(function(a, b) { return words[b].count - words[a].count });
        var $definition = $(lexicon[lemma]);
        $carousel.find(".carousel-inner")
          .append("<div class='item'><p>" + lemma + "</p><div class='carousel-caption'><p>" + forms.join(", ") + "</p></div></div>")
          .append("<div class='item'><p>" + $definition.html() + "</p></div>");
        $("<tr><td>" + lemma + "</td><td>" + partOfSpeech[lemma].count + "</td></tr>")
          .append((function() {
            var cell = $("<td></td>");
            for (var i = 0; i < forms.length; i++) {
              if (i == 3) break;

              var span = words[forms[i]].word;
              $("<span data-toggle='tooltip' title='" + inflections(span) + "'>" + span.text() + "</span>")
                .appendTo(cell);
              if (i < 2 && i < forms.length - 1) cell.append(", ")
            }
            return cell;
          })())
          .append($("<td>" + $definition.find(".translation:first").text() + "</td>"))
          .appendTo($tbody);
      }
    });
    $carousel.find(".item").first().addClass('active');
    $table.find("span[data-toggle]").tooltip();
    $('#vocabulary').modal();
    return false;
  });
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
